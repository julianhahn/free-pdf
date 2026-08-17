//! Paints what `find_paper` calls the paper over the photo, so the mask can be
//! looked at instead of counted. Red is the mask, green the `bounds` rectangle,
//! blue crosses the four `corners()`.
//!
//! Not a test and not shipped code: it has a `main` and unwraps freely.
//!
//! ```sh
//! cargo run -p core_engine --example mask -- <photo> <overlay.png>
//! ```

use core_engine::{find_paper, load_image};
use image::{Rgba, RgbaImage};
use std::path::Path;

fn main() {
    let mut args = std::env::args().skip(1);
    let input = args.next().expect("usage: mask <in> <out.png>");
    let output = args.next().expect("usage: mask <in> <out.png>");

    let img = load_image(Path::new(&input)).unwrap();
    let (width, height) = (img.width(), img.height());
    let mut canvas: RgbaImage = img.to_rgba8();

    let paper = match find_paper(&img) {
        Some(paper) => paper,
        None => {
            println!("{input}: {width}x{height} find_paper = None");
            canvas.save(&output).unwrap();
            return;
        }
    };

    for y in 0..height {
        for x in 0..width {
            if paper.contains(x, y) {
                let pixel = canvas.get_pixel_mut(x, y);
                pixel[0] = (pixel[0] as u32 / 2 + 128) as u8;
                pixel[1] /= 2;
                pixel[2] /= 2;
            }
        }
    }

    let green = Rgba([0, 255, 0, 255]);
    let thickness = (width / 300).max(2);
    let bounds = paper.bounds;
    for t in 0..thickness {
        rectangle(&mut canvas, bounds, t, green);
    }

    for (index, corner) in paper.corners().iter().enumerate() {
        // Darker blue for later corners, so the order round the shape is visible.
        let blue = Rgba([0, 40 * index as u8, 255, 255]);
        cross(
            &mut canvas,
            corner.x as i64,
            corner.y as i64,
            blue,
            width / 30,
        );
    }

    canvas.save(&output).unwrap();
    println!(
        "{input}: {width}x{height} bounds={bounds:?} runs_off={} whole={} corners={:?}",
        paper.runs_off_the_picture(),
        paper.is_the_whole_image(),
        paper
            .corners()
            .map(|point| (point.x as i32, point.y as i32)),
    );
}

fn rectangle(canvas: &mut RgbaImage, rect: core_engine::Rect, inset: u32, colour: Rgba<u8>) {
    let right = rect.x + rect.width - 1;
    let bottom = rect.y + rect.height - 1;
    for x in rect.x..=right {
        put(canvas, x as i64, (rect.y + inset) as i64, colour);
        put(canvas, x as i64, bottom as i64 - inset as i64, colour);
    }
    for y in rect.y..=bottom {
        put(canvas, (rect.x + inset) as i64, y as i64, colour);
        put(canvas, right as i64 - inset as i64, y as i64, colour);
    }
}

fn cross(canvas: &mut RgbaImage, x: i64, y: i64, colour: Rgba<u8>, arm: u32) {
    let arm = arm as i64;
    for step in -arm..=arm {
        for thick in -3..=3 {
            put(canvas, x + step, y + thick, colour);
            put(canvas, x + thick, y + step, colour);
        }
    }
}

fn put(canvas: &mut RgbaImage, x: i64, y: i64, colour: Rgba<u8>) {
    if x >= 0 && y >= 0 && x < canvas.width() as i64 && y < canvas.height() as i64 {
        canvas.put_pixel(x as u32, y as u32, colour);
    }
}
