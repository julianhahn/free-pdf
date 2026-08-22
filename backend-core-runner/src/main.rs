//! Command line front end for the core engine.
//!
//! It drives the same flow a graphical client would: load each image, then ask
//! the engine for one PDF. The engine holds the logic, this file only reads
//! arguments and prints what happened.

use core_engine::{
    apply_levels, crop, deskew, find_paper, fit_within, images_to_pdf, load_image, pages_to_pdf,
    rotate, save_page, sharpen, straighten, suggest_levels, suggest_straightening, to_grayscale,
    DynamicImage, PageQuality,
};
use std::path::{Path, PathBuf};
use std::process::ExitCode;

const USAGE: &str = "\
usage: backend-core-runner <image>... -o <out.pdf|out.jpeg> [tools]

  <image>...          one or more photos or scans, in page order. JPEG, PNG,
                      and on macOS also the HEIC files an iPhone produces.
  -o, --output <f>    where to write. A .pdf holds every page; any image
                      extension writes the single processed image, so a step
                      can be looked at before the next one is chosen.
  -h, --help          show this text

  --scan              the usual way: --deskew --straighten --levels --sharpen 0.6

  --quality <1..100>  how hard every page of a .pdf is compressed. Left out, the
                      PDF is written exactly as it was written before this flag
                      existed. With --long-edge these are the two numbers behind
                      a page size setting; the names a user reads for them belong
                      to the client that offers them, not here.

tools, applied to every image in this order:
  --rotate <n>        turn clockwise by 90, 180 or 270 degrees
  --crop <x,y,w,h>    cut to a box, in pixels, measured after rotating
  --auto-crop         cut to the sheet of paper the engine finds by itself
  --deskew            pull the sheet straight, as if seen from straight above
  --straighten        turn crooked writing back level, measured off the writing
                      itself, so it works where the sheet cannot be found
  --levels            paper to white, writing to black, colour cast removed
  --long-edge <px>    shrink until neither edge is longer than that. Before
                      sharpening, or the sharpening is thrown away again
  --sharpen <r>       make edges crisper, radius in pixels (around 1 for text)
  --gray              drop the colour
";

/// What --scan sharpens by. Measured against a hand edit of the same photo: at this
/// radius the result matched it, and more starts to draw halos around the letters.
const SCAN_SHARPEN: f32 = 0.6;

fn main() -> ExitCode {
    let args: Vec<String> = std::env::args().skip(1).collect();

    if args.is_empty() || args.iter().any(|a| a == "-h" || a == "--help") {
        println!("{USAGE}");
        return ExitCode::SUCCESS;
    }

    match run(&args) {
        Ok(out_path) => {
            println!("Wrote {}", out_path.display());
            ExitCode::SUCCESS
        }
        Err(message) => {
            eprintln!("Error: {message}");
            ExitCode::FAILURE
        }
    }
}

fn run(args: &[String]) -> Result<PathBuf, String> {
    let args = parse_args(args)?;

    let mut pages = Vec::with_capacity(args.inputs.len());
    for path in &args.inputs {
        let page = apply_tools(load_photo(path)?, &args)?;
        println!("{}: {}x{}", path.display(), page.width(), page.height());
        pages.push(page);
    }

    write_output(&pages, &args.output, args.quality)?;
    Ok(args.output)
}

/// Loads a photo, letting the operating system deal with HEIC first.
///
/// A HEIC file from an iPhone is video compression (HEVC) in a still-image
/// container. Decoding it means shipping an HEVC decoder, which carries patent
/// licensing that a small offline tool has no business taking on - and every
/// target platform already has a licensed decoder installed. So this knowledge
/// lives here in the client, not in the engine: the engine stays a pure Rust
/// library that reads plain image formats, and each client hands it something
/// its own operating system could open.
fn load_photo(path: &Path) -> Result<DynamicImage, String> {
    if !is_heic(path) {
        return load_image(path);
    }

    let converted = convert_heic(path)?;
    let loaded = load_image(&converted);
    let _ = std::fs::remove_file(&converted);
    loaded
}

fn is_heic(path: &Path) -> bool {
    path.extension().is_some_and(|extension| {
        extension.eq_ignore_ascii_case("heic") || extension.eq_ignore_ascii_case("heif")
    })
}

/// Hands the HEIC to macOS and gets a plain JPEG back.
///
/// The rotation is not touched here on purpose: the converted file keeps the
/// camera rotation as a tag, exactly as the original had it, so the engine's own
/// upright handling stays the single place that deals with it.
#[cfg(target_os = "macos")]
fn convert_heic(path: &Path) -> Result<PathBuf, String> {
    use std::process::{Command, Stdio};

    // The iPhone shoots in Display P3. Converting to sRGB here means the colours
    // are translated properly, instead of P3 numbers being read later as sRGB
    // and coming out oversaturated.
    const SRGB_PROFILE: &str = "/System/Library/ColorSync/Profiles/sRGB Profile.icc";

    let converted = std::env::temp_dir().join(format!("freepdf-heic-{}.jpg", std::process::id()));

    let mut sips = Command::new("sips");
    sips.args(["-s", "format", "jpeg", "-s", "formatOptions", "best"]);
    if Path::new(SRGB_PROFILE).exists() {
        sips.args(["-m", SRGB_PROFILE]);
    }
    let finished = sips
        .arg(path)
        .arg("--out")
        .arg(&converted)
        .stdout(Stdio::null())
        .status()
        .map_err(|e| format!("Could not run sips to read {}: {}", path.display(), e))?;

    // sips reports success even when it skipped the file, so the result has to be
    // looked at rather than trusted.
    let written = converted.metadata().map(|file| file.len()).unwrap_or(0);
    if !finished.success() || written == 0 {
        let _ = std::fs::remove_file(&converted);
        return Err(format!(
            "macOS could not read {} as an image.",
            path.display()
        ));
    }

    Ok(converted)
}

#[cfg(not(target_os = "macos"))]
fn convert_heic(path: &Path) -> Result<PathBuf, String> {
    Err(format!(
        "{} is a HEIC file, and this build has no way to read one. HEIC needs a \
         decoder the operating system provides; on macOS that happens \
         automatically. Convert the file to JPEG first.",
        path.display()
    ))
}

/// Runs the tools the user asked for, in the order the help text promises.
fn apply_tools(img: DynamicImage, args: &Args) -> Result<DynamicImage, String> {
    let mut img = img;

    if let Some(degrees) = args.rotate {
        img = rotate(&img, degrees)?;
    }
    if let Some((x, y, width, height)) = args.crop {
        img = crop(&img, x, y, width, height)?;
    }
    if args.auto_crop {
        match find_paper(&img) {
            Some(sheet) if sheet.is_the_whole_image() => {
                println!("  paper: fills the picture, nothing to cut away")
            }
            Some(sheet) => {
                let box_ = sheet.bounds;
                println!(
                    "  paper: {}x{} at ({}, {})",
                    box_.width, box_.height, box_.x, box_.y
                );
                img = crop(&img, box_.x, box_.y, box_.width, box_.height)?;
            }
            None => println!("  paper: no sheet found, left as it is"),
        }
    }
    if args.deskew {
        match find_paper(&img) {
            Some(sheet) => {
                if sheet.runs_off_the_picture() {
                    println!(
                        "  deskew: the sheet runs off the edge of the photo, so the page \
                         is a piece of the sheet, not the whole of it"
                    );
                }
                let corners = sheet.corners();
                println!(
                    "  deskew: corners {}",
                    corners
                        .iter()
                        .map(|c| format!("({:.0},{:.0})", c.x, c.y))
                        .collect::<Vec<_>>()
                        .join(" ")
                );
                img = deskew(&img, corners)?;
            }
            None => println!(
                "  deskew: no sheet found - a darker surface under the document would \
                 help, or --straighten instead"
            ),
        }
    }
    if args.straighten {
        let degrees = suggest_straightening(&img);
        if degrees == 0.0 {
            println!("  straighten: no crooked lines of writing found, left as it is");
        } else {
            println!("  straighten: turning by {degrees:.1} degrees");
            img = straighten(&img, degrees)?;
        }
    }
    if args.levels {
        let suggestion = suggest_levels(&img);
        if suggestion.are_unchanged() {
            println!("  levels: no paper found to stretch, left as it is");
        } else {
            println!(
                "  levels: black {:?}, white {:?}",
                suggestion.black, suggestion.white
            );
        }
        img = apply_levels(&img, suggestion);
    }
    if let Some(edge) = args.long_edge {
        // Before sharpening, exactly where the phone's own size cap sits: a page
        // shrunk afterwards throws the sharpening away. The runner has no memory
        // cap of its own (AGENTS.md), so this number is a page size and nothing
        // else.
        if img.width().max(img.height()) <= edge {
            println!("  page size: already inside {edge} px, left as it is");
        }
        img = fit_within(&img, edge)?;
    }
    if let Some(radius) = args.sharpen {
        img = sharpen(&img, radius)?;
    }
    if args.gray {
        img = to_grayscale(&img);
    }

    Ok(img)
}

/// A `.pdf` output collects every page; any other extension writes the single
/// processed image, which is how a step can be inspected before the next one.
///
/// A PDF asked for at a quality takes the road the phone takes: one `save_page`
/// per page, then `pages_to_pdf` over the paths. `images_to_pdf` has no quality to
/// set and is frozen, together with the two tests that count the bytes it writes
/// ([../core_engine/AGENTS.md](../../core_engine/AGENTS.md)). Without `--quality`
/// nothing about that older road moves.
fn write_output(pages: &[DynamicImage], output: &Path, quality: Option<u8>) -> Result<(), String> {
    if is_pdf(output) {
        return match quality {
            Some(jpeg_quality) => write_pdf_page_by_page(pages, output, jpeg_quality),
            None => images_to_pdf(pages, output),
        };
    }

    match pages {
        [single] => single
            .save(output)
            .map_err(|e| format!("Failed to write {}: {}", output.display(), e)),
        _ => Err(format!(
            "Writing an image file takes exactly one input image, but {} were given. \
             Use a .pdf output to hold several pages.",
            pages.len()
        )),
    }
}

/// Whether that name asks for a PDF. The extension decides, as it does for every
/// other output.
fn is_pdf(output: &Path) -> bool {
    output
        .extension()
        .is_some_and(|ext| ext.eq_ignore_ascii_case("pdf"))
}

/// Writes every page as its own JPEG at that quality, then stitches the paths into
/// the PDF, which is how a phone builds one.
///
/// The pages wait in a folder of this run's own, named after the process, so two
/// runs at the same time cannot read each other's pages. They are removed again
/// whether the PDF came out or not: they are working files, not output.
fn write_pdf_page_by_page(
    pages: &[DynamicImage],
    output: &Path,
    jpeg_quality: u8,
) -> Result<(), String> {
    let folder = std::env::temp_dir().join(format!("freepdf-pages-{}", std::process::id()));
    std::fs::create_dir_all(&folder).map_err(|e| {
        format!(
            "Failed to make the folder for the pages at {}: {}",
            folder.display(),
            e
        )
    })?;

    let quality = PageQuality {
        jpeg_quality,
        // Every pixel: the shrinking already happened in `apply_tools`, before the
        // sharpening, and `save_page` refuses to do it here for that same reason.
        longest_edge: PageQuality::UNCHANGED.longest_edge,
    };
    let written = write_pages(pages, &folder, quality).and_then(|paths| {
        println!("  pages: {} written at quality {jpeg_quality}", paths.len());
        pages_to_pdf(&paths, output)
    });

    let _ = std::fs::remove_dir_all(&folder);
    written
}

/// One JPEG per page, numbered so the list keeps the order the pages came in.
fn write_pages(
    pages: &[DynamicImage],
    folder: &Path,
    quality: PageQuality,
) -> Result<Vec<PathBuf>, String> {
    let mut paths = Vec::with_capacity(pages.len());
    for (number, page) in pages.iter().enumerate() {
        let path = folder.join(format!("{:04}.jpg", number + 1));
        save_page(page, &path, quality)?;
        paths.push(path);
    }
    Ok(paths)
}

struct Args {
    inputs: Vec<PathBuf>,
    output: PathBuf,
    rotate: Option<u32>,
    crop: Option<(u32, u32, u32, u32)>,
    auto_crop: bool,
    deskew: bool,
    straighten: bool,
    levels: bool,
    long_edge: Option<u32>,
    sharpen: Option<f32>,
    gray: bool,
    quality: Option<u8>,
}

fn parse_args(args: &[String]) -> Result<Args, String> {
    let mut inputs = Vec::new();
    let mut output = None;
    let mut rotate = None;
    let mut crop = None;
    let mut auto_crop = false;
    let mut deskew_it = false;
    let mut straighten_it = false;
    let mut levels = false;
    let mut long_edge = None;
    let mut sharpen_radius = None;
    let mut gray = false;
    let mut quality = None;
    let mut scan = false;

    let mut args = args.iter();
    while let Some(arg) = args.next() {
        match arg.as_str() {
            "-o" | "--output" => output = Some(PathBuf::from(value_for(arg, &mut args)?)),
            "--rotate" => rotate = Some(parse_number(value_for(arg, &mut args)?, "--rotate")?),
            "--crop" => crop = Some(parse_crop_box(value_for(arg, &mut args)?)?),
            "--auto-crop" => auto_crop = true,
            "--deskew" => deskew_it = true,
            "--straighten" => straighten_it = true,
            "--levels" => levels = true,
            "--long-edge" => {
                long_edge = Some(parse_number(value_for(arg, &mut args)?, "--long-edge")?)
            }
            "--quality" => quality = Some(parse_quality(value_for(arg, &mut args)?)?),
            "--sharpen" => {
                let value = value_for(arg, &mut args)?;
                sharpen_radius = Some(
                    value
                        .parse()
                        .map_err(|_| format!("--sharpen needs a number, but got {value:?}."))?,
                );
            }
            "--scan" => scan = true,
            "--gray" | "--grayscale" => gray = true,
            unknown if unknown.starts_with('-') => {
                return Err(format!("Unknown option {unknown}.\n\n{USAGE}"))
            }
            input => inputs.push(PathBuf::from(input)),
        }
    }

    if inputs.is_empty() {
        return Err(format!("No input images given.\n\n{USAGE}"));
    }

    if scan {
        deskew_it = true;
        straighten_it = true;
        levels = true;
        // Only where nothing was asked for, so --scan --sharpen 1.2 keeps the 1.2
        // however the two are ordered.
        sharpen_radius = sharpen_radius.or(Some(SCAN_SHARPEN));
    }

    let output = output.ok_or_else(|| format!("No output file given.\n\n{USAGE}"))?;
    // A number that quietly does nothing reads as a broken flag, so asking for a
    // page quality next to an image output is answered instead of ignored. Only a
    // PDF has pages, and only `save_page` takes a quality.
    if quality.is_some() && !is_pdf(&output) {
        return Err(format!(
            "--quality only changes the pages of a PDF, but the output is {}. \
             Ask for a .pdf, or leave --quality out.\n\n{USAGE}",
            output.display()
        ));
    }

    Ok(Args {
        inputs,
        output,
        rotate,
        crop,
        auto_crop,
        deskew: deskew_it,
        straighten: straighten_it,
        levels,
        long_edge,
        sharpen: sharpen_radius,
        gray,
        quality,
    })
}

/// The page qualities `save_page` counts in.
///
/// Checked while the arguments are read, so a typo is answered before the first
/// photo is opened instead of after the last one is processed. `save_page` checks
/// the same range again for its own callers, and USAGE prints it for the user.
const QUALITY_RANGE: std::ops::RangeInclusive<u8> = 1..=100;

/// Reads the JPEG quality of a page, refusing anything outside the range in one
/// sentence - a number too big for the range and one too big for a byte are the
/// same mistake to the person who typed it.
fn parse_quality(value: &str) -> Result<u8, String> {
    match value.parse::<u8>() {
        Ok(quality) if QUALITY_RANGE.contains(&quality) => Ok(quality),
        _ => Err(format!(
            "--quality takes a number from {} to {}, but got {value:?}.",
            QUALITY_RANGE.start(),
            QUALITY_RANGE.end()
        )),
    }
}

/// Reads the four numbers of a crop box, given as "x,y,width,height".
fn parse_crop_box(value: &str) -> Result<(u32, u32, u32, u32), String> {
    let numbers: Vec<u32> = value
        .split(',')
        .map(|part| parse_number(part.trim(), "--crop"))
        .collect::<Result<_, _>>()?;

    match numbers[..] {
        [x, y, width, height] => Ok((x, y, width, height)),
        _ => Err(format!(
            "--crop needs four numbers as x,y,width,height, but got {value:?}."
        )),
    }
}

fn parse_number(value: &str, option: &str) -> Result<u32, String> {
    value
        .parse()
        .map_err(|_| format!("{option} needs whole numbers, but got {value:?}."))
}

/// The HEIC path is only testable where a decoder exists, so these run on macOS.
/// The test builds its own HEIC with the same operating system tool, which keeps
/// a real photo out of the repository.
#[cfg(all(test, target_os = "macos"))]
mod heic_tests {
    use super::*;

    fn temp_path(name: &str) -> PathBuf {
        std::env::temp_dir().join(format!("freepdf-heic-test-{name}"))
    }

    #[test]
    fn a_heic_file_is_read_like_any_other_photo() {
        let jpeg = temp_path("source.jpeg");
        let heic = temp_path("photo.heic");
        DynamicImage::ImageRgb8(image::RgbImage::from_pixel(
            64,
            48,
            image::Rgb([200, 190, 170]),
        ))
        .save(&jpeg)
        .expect("could not write the source image");
        let converted = std::process::Command::new("sips")
            .args(["-s", "format", "heic"])
            .arg(&jpeg)
            .arg("--out")
            .arg(&heic)
            .stdout(std::process::Stdio::null())
            .status()
            .expect("could not run sips");
        assert!(
            converted.success() && heic.metadata().is_ok_and(|f| f.len() > 0),
            "this macOS could not write a HEIC to test against"
        );

        let loaded = load_photo(&heic).expect("reading the HEIC failed");

        assert_eq!((loaded.width(), loaded.height()), (64, 48));
    }

    #[test]
    fn a_broken_heic_reports_an_error_instead_of_panicking() {
        let broken = temp_path("broken.heic");
        std::fs::write(&broken, b"this is not a photo").expect("could not write the test file");

        // sips reports success on a file it skipped, so this is exactly the case
        // where trusting the exit code would hand an empty file to the engine.
        assert!(load_photo(&broken).is_err());
    }

    #[test]
    fn a_missing_heic_reports_an_error() {
        let missing = temp_path("not-here.heic");
        let _ = std::fs::remove_file(&missing);

        assert!(load_photo(&missing).is_err());
    }
}

/// Reads the value that belongs to an option, so a missing value is reported as
/// such instead of swallowing the next argument.
fn value_for<'a>(
    option: &str,
    args: &mut impl Iterator<Item = &'a String>,
) -> Result<&'a String, String> {
    match args.next() {
        Some(value) if !value.starts_with('-') => Ok(value),
        _ => Err(format!("{option} needs a value.\n\n{USAGE}")),
    }
}

#[cfg(test)]
mod scan_tests {
    use super::*;

    fn parse(line: &str) -> Args {
        let words: Vec<String> = line.split_whitespace().map(String::from).collect();
        parse_args(&words).expect("these arguments should parse")
    }

    #[test]
    fn scan_stands_for_the_usual_four_tools() {
        let args = parse("photo.jpg -o out.pdf --scan");

        assert!(args.deskew && args.straighten && args.levels);
        assert_eq!(args.sharpen, Some(SCAN_SHARPEN));
    }

    /// The two numbers of a page size are read as numbers, and nothing else: the
    /// rung names the user reads belong to the client that offers them.
    #[test]
    fn a_page_size_is_read_as_two_plain_numbers() {
        let args = parse("photo.jpg -o out.pdf --scan --quality 45 --long-edge 1700");

        assert_eq!(args.quality, Some(45));
        assert_eq!(args.long_edge, Some(1700));
    }

    /// Only a PDF has pages, so a quality asked for next to an image output has to
    /// be answered. Carried out silently on nothing, it would look like the flag is
    /// broken.
    #[test]
    fn a_quality_asked_for_next_to_an_image_output_is_refused() {
        let words: Vec<String> = "photo.jpg -o page.jpeg --quality 45"
            .split_whitespace()
            .map(String::from)
            .collect();

        let refused = parse_args(&words).err().unwrap_or_default();

        assert!(
            refused.contains("--quality only changes the pages of a PDF"),
            "{refused}"
        );
    }

    /// A quality no encoder counts in is answered while the arguments are read, so
    /// the user hears about his typo before forty photos are processed.
    #[test]
    fn a_quality_outside_the_range_is_refused_before_a_photo_is_opened() {
        let words: Vec<String> = "photo.jpg -o out.pdf --quality 300"
            .split_whitespace()
            .map(String::from)
            .collect();

        let refused = parse_args(&words).err().unwrap_or_default();

        assert_eq!(
            refused,
            "--quality takes a number from 1 to 100, but got \"300\"."
        );
    }

    #[test]
    fn a_sharpness_asked_for_by_hand_survives_scan() {
        // Either order: the shorthand fills in what is missing, it does not overrule.
        for line in [
            "photo.jpg -o out.pdf --scan --sharpen 1.2",
            "photo.jpg -o out.pdf --sharpen 1.2 --scan",
        ] {
            assert_eq!(parse(line).sharpen, Some(1.2), "{line}");
        }
    }
}
