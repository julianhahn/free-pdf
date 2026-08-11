//! Development tool: measures how one image differs from another.
//!
//! Used to work out what a manual photo edit actually did, so the engine can be
//! built to do the same thing on purpose instead of by feel.
//!
//!   cargo run -p core_engine --example compare -- original.jpeg edited.jpeg
//!
//! The edited image is expected to be a crop of the original, possibly with any
//! amount of tone, colour and sharpness work on top. The tool first finds where
//! the crop sits, then compares only the region the two images share.

use image::{DynamicImage, GrayImage, RgbImage};

fn main() {
    let mut args = std::env::args().skip(1);
    let (before_path, after_path) = match (args.next(), args.next()) {
        (Some(a), Some(b)) => (a, b),
        _ => {
            eprintln!("usage: compare <original> <edited>");
            std::process::exit(1);
        }
    };

    let before = core_engine::load_image(std::path::Path::new(&before_path)).unwrap();
    let after = core_engine::load_image(std::path::Path::new(&after_path)).unwrap();

    println!("original  {}x{}", before.width(), before.height());
    println!("edited    {}x{}", after.width(), after.height());

    let (offset_x, offset_y, score) = find_crop_offset(&before, &after);
    println!(
        "\ncrop      the edited image sits at ({offset_x}, {offset_y}) in the original, \
         gradient match {score:.3}"
    );
    println!(
        "          cut away: {} px left, {} px right, {} px top, {} px bottom",
        offset_x,
        before.width() - after.width() - offset_x,
        offset_y,
        before.height() - after.height() - offset_y
    );

    let cropped = before
        .crop_imm(offset_x, offset_y, after.width(), after.height())
        .to_rgb8();
    let edited = after.to_rgb8();

    report_histogram(&cropped, &edited);
    report_levels(&cropped, &edited);
    report_tone_curve(&cropped, &edited);
    report_saturation(&cropped, &edited);
    report_sharpness(&cropped, &edited);
}

/// Finds where the smaller image sits inside the larger one.
///
/// Compares edge strength rather than brightness, because the whole point is
/// that brightness was changed. A coarse pass on eighth-size images picks the
/// area, a fine pass checks every offset around it.
fn find_crop_offset(before: &DynamicImage, after: &DynamicImage) -> (u32, u32, f64) {
    const COARSE: u32 = 8;

    let small_before = shrink(before, COARSE);
    let small_after = shrink(after, COARSE);
    let (coarse_x, coarse_y, _) = best_offset(&small_before, &small_after, 0, 0, u32::MAX);

    let before_edges = edges(&before.to_luma8());
    let after_edges = edges(&after.to_luma8());
    let from_x = (coarse_x * COARSE).saturating_sub(COARSE * 2);
    let from_y = (coarse_y * COARSE).saturating_sub(COARSE * 2);

    best_offset(&before_edges, &after_edges, from_x, from_y, COARSE * 4)
}

fn shrink(img: &DynamicImage, factor: u32) -> GrayImage {
    let small = img.resize_exact(
        img.width() / factor,
        img.height() / factor,
        image::imageops::FilterType::Triangle,
    );
    edges(&small.to_luma8())
}

/// Edge strength per pixel: how much the brightness changes to the right and
/// downwards. Survives any brightness or contrast change applied later.
fn edges(luma: &GrayImage) -> GrayImage {
    let (width, height) = (luma.width(), luma.height());
    let mut out = GrayImage::new(width, height);

    for y in 0..height.saturating_sub(1) {
        for x in 0..width.saturating_sub(1) {
            let here = luma.get_pixel(x, y)[0] as i32;
            let right = luma.get_pixel(x + 1, y)[0] as i32;
            let below = luma.get_pixel(x, y + 1)[0] as i32;
            let strength = (right - here).abs() + (below - here).abs();
            out.put_pixel(x, y, image::Luma([strength.min(255) as u8]));
        }
    }

    out
}

/// Tries every offset in a window and returns the one where the edges line up
/// best, measured as correlation so a difference in edge contrast does not
/// decide the outcome.
fn best_offset(
    haystack: &GrayImage,
    needle: &GrayImage,
    from_x: u32,
    from_y: u32,
    window: u32,
) -> (u32, u32, f64) {
    let max_x = haystack.width() - needle.width();
    let max_y = haystack.height() - needle.height();
    let to_x = (from_x + window).min(max_x);
    let to_y = (from_y + window).min(max_y);

    let mut best = (0, 0, f64::MIN);
    for offset_y in from_y..=to_y {
        for offset_x in from_x..=to_x {
            let score = correlation(haystack, needle, offset_x, offset_y);
            if score > best.2 {
                best = (offset_x, offset_y, score);
            }
        }
    }

    best
}

/// Pearson correlation of two equally sized pixel fields, sampled every third
/// pixel: enough signal to rank offsets, a ninth of the work.
fn correlation(haystack: &GrayImage, needle: &GrayImage, offset_x: u32, offset_y: u32) -> f64 {
    const STEP: u32 = 3;
    let (mut sum_a, mut sum_b, mut sum_aa, mut sum_bb, mut sum_ab) = (0f64, 0f64, 0f64, 0f64, 0f64);
    let mut count = 0f64;

    for y in (0..needle.height()).step_by(STEP as usize) {
        for x in (0..needle.width()).step_by(STEP as usize) {
            let a = haystack.get_pixel(x + offset_x, y + offset_y)[0] as f64;
            let b = needle.get_pixel(x, y)[0] as f64;
            sum_a += a;
            sum_b += b;
            sum_aa += a * a;
            sum_bb += b * b;
            sum_ab += a * b;
            count += 1.0;
        }
    }

    let covariance = sum_ab / count - (sum_a / count) * (sum_b / count);
    let spread_a = (sum_aa / count - (sum_a / count).powi(2)).sqrt();
    let spread_b = (sum_bb / count - (sum_b / count).powi(2)).sqrt();

    if spread_a == 0.0 || spread_b == 0.0 {
        return 0.0;
    }
    covariance / (spread_a * spread_b)
}

/// How the brightness values are spread out. A photo of a document has two
/// humps: a big one where the paper is and a small one where the ink is. Knowing
/// where they sit is what lets the engine pick its own levels later.
fn report_histogram(before: &RgbImage, after: &RgbImage) {
    println!("\nbrightness spread (each row is a range of 8 values)");
    println!("  value   original                      edited");

    // Each side is scaled to its own tallest bar: the edited image puts almost
    // everything into one bucket, and a shared scale would flatten the original
    // into nothing.
    let (b, a) = (histogram(before), histogram(after));
    let scale_b = *b.iter().max().unwrap_or(&1) as f64;
    let scale_a = *a.iter().max().unwrap_or(&1) as f64;

    // The share of the tallest bar is printed as well as drawn: designing a rule
    // around "is this bucket empty" needs the number, not a picture of it.
    for bucket in 0..32 {
        let value = bucket * 8;
        let share_b = b[bucket] as f64 / scale_b * 100.0;
        let bar_b = "#".repeat((share_b / 100.0 * 20.0).round() as usize);
        let share_a = a[bucket] as f64 / scale_a * 100.0;
        println!("  {value:>3}  {share_b:>5.1}% {bar_b:<20}  {share_a:>5.1}%");
    }
}

fn histogram(img: &RgbImage) -> [u32; 32] {
    let mut buckets = [0u32; 32];
    for p in img.pixels() {
        buckets[(luma(p) / 8) as usize] += 1;
    }
    buckets
}

/// Where the black and white ends of the brightness range sit, and how much of
/// the image is plain paper white.
fn report_levels(before: &RgbImage, after: &RgbImage) {
    println!("\nbrightness            original   edited");
    let (b, a) = (luma_values(before), luma_values(after));

    for (label, pick) in [
        ("darkest 1%", 0.01),
        ("darkest 5%", 0.05),
        ("middle", 0.50),
        ("brightest 5%", 0.95),
        ("brightest 1%", 0.99),
    ] {
        println!(
            "  {label:<20} {:>6}   {:>6}",
            percentile(&b, pick),
            percentile(&a, pick)
        );
    }

    let white_before = b.iter().filter(|&&v| v >= 250).count() * 100 / b.len();
    let white_after = a.iter().filter(|&&v| v >= 250).count() * 100 / a.len();
    println!("  near-white pixels    {white_before:>5}%   {white_after:>5}%");

    let dark_before = b.iter().filter(|&&v| v <= 60).count() * 100 / b.len();
    let dark_after = a.iter().filter(|&&v| v <= 60).count() * 100 / a.len();
    println!("  near-black pixels    {dark_before:>5}%   {dark_after:>5}%");
}

/// The brightness that came out for every brightness that went in. This is the
/// edit's tone curve, measured rather than guessed.
fn report_tone_curve(before: &RgbImage, after: &RgbImage) {
    let mut sums = [0f64; 256];
    let mut counts = [0f64; 256];

    for (p, q) in before.pixels().zip(after.pixels()) {
        let input = luma(p) as usize;
        sums[input] += luma(q) as f64;
        counts[input] += 1.0;
    }

    println!("\ntone curve (input brightness -> average output brightness)");
    for input in (0..=240).step_by(16) {
        let (sum, count) = (sums[input], counts[input]);
        if count < 50.0 {
            println!("  {input:>3} ->   (too few pixels)");
            continue;
        }
        let output = sum / count;
        let bar = "#".repeat((output / 8.0).round() as usize);
        println!("  {input:>3} -> {output:>5.1}  {bar}");
    }
}

fn report_saturation(before: &RgbImage, after: &RgbImage) {
    println!("\ncolour");
    println!(
        "  average saturation   {:>5.1}%   {:>5.1}%",
        mean_saturation(before) * 100.0,
        mean_saturation(after) * 100.0
    );

    let (br, bg, bb) = mean_channels(before);
    let (ar, ag, ab) = mean_channels(after);
    println!("  average red          {br:>5.1}    {ar:>5.1}");
    println!("  average green        {bg:>5.1}    {ag:>5.1}");
    println!("  average blue         {bb:>5.1}    {ab:>5.1}");
    println!(
        "  warm cast (r-b)      {:>5.1}    {:>5.1}",
        br - bb,
        ar - ab
    );
}

/// How strong the local detail is. Text that has been sharpened shows a higher
/// value; a blurred image a lower one.
fn report_sharpness(before: &RgbImage, after: &RgbImage) {
    println!("\nsharpness");
    println!(
        "  detail energy        {:>7.1}   {:>7.1}",
        detail(before),
        detail(after)
    );
}

fn detail(img: &RgbImage) -> f64 {
    let mut total = 0f64;
    let mut count = 0f64;

    for y in 1..img.height() - 1 {
        for x in 1..img.width() - 1 {
            let centre = luma(img.get_pixel(x, y)) as f64 * 4.0;
            let around = luma(img.get_pixel(x - 1, y)) as f64
                + luma(img.get_pixel(x + 1, y)) as f64
                + luma(img.get_pixel(x, y - 1)) as f64
                + luma(img.get_pixel(x, y + 1)) as f64;
            total += (centre - around).powi(2);
            count += 1.0;
        }
    }

    (total / count).sqrt()
}

fn luma(p: &image::Rgb<u8>) -> u8 {
    let [r, g, b] = p.0;
    (0.299 * r as f32 + 0.587 * g as f32 + 0.114 * b as f32).round() as u8
}

fn luma_values(img: &RgbImage) -> Vec<u8> {
    let mut values: Vec<u8> = img.pixels().map(luma).collect();
    values.sort_unstable();
    values
}

fn percentile(sorted: &[u8], fraction: f64) -> u8 {
    let index = ((sorted.len() - 1) as f64 * fraction).round() as usize;
    sorted[index]
}

fn mean_saturation(img: &RgbImage) -> f64 {
    let mut total = 0f64;
    for p in img.pixels() {
        let [r, g, b] = p.0;
        let high = r.max(g).max(b) as f64;
        let low = r.min(g).min(b) as f64;
        total += if high == 0.0 {
            0.0
        } else {
            (high - low) / high
        };
    }
    total / img.pixels().len() as f64
}

fn mean_channels(img: &RgbImage) -> (f64, f64, f64) {
    let (mut r, mut g, mut b) = (0f64, 0f64, 0f64);
    for p in img.pixels() {
        r += p[0] as f64;
        g += p[1] as f64;
        b += p[2] as f64;
    }
    let n = img.pixels().len() as f64;
    (r / n, g / n, b / n)
}
