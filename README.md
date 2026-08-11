# FreePDF Suite: Cross-Platform Local PDF Utility
**Project Scope:** Develop a comprehensive suite of desktop and mobile applications for professional local handling of Portable Document Format (PDF) files. The entire system operates completely offline, eliminating reliance on network connectivity or cloud services.

## ⚙️ Architecture & Technical Foundation
### The Core Engine Principle
The heart of the FreePDF Suite is the **`core_engine`** library, written in Rust. All logic resides here and must be exposed via a stable **C Foreign Function Interface (FFI)** wrapper. The clients merely call functions; they do not implement the complex PDF processing logic. 

### Component Breakdown
1.  **`core_engine` (Rust):** Handles all image manipulation, transformation calculations (deskewing, color correction), and final PDF stitching. It accepts input data or paths and executes specific requested tasks.
2.  **Client Layer (Starting with Windows):** The native UI wrapper. This layer is crucial as it manages the **step-by-step user interaction**, allowing the user to manually intervene at every stage of processing.

## 📜 Development Guidelines & Constraints
*   **Offline Only:** All features must operate purely on local file system resources. No external APIs or network calls are permitted.
*   **Principle of User Control:** The process *must* be guided by the user interface. Instead of automated pipelines, we expose individual tools that the user clicks in order: **Tool A $\rightarrow$ Tool B $\rightarrow$ Tool C.**
*   **Safety First:** Robust error handling is mandatory for corrupted files and invalid inputs.

## 🚀 Development Roadmap (Phase I: The Manual Scan Workflow)

### Phase I - MVP Goal: Modular Photo Toolkit & Windows Client Demo
(Goal: Allow the user to take a photo, interactively refine it through dedicated tools, and then stitch it into a single PDF.)

### What the engine does today

Photo in, PDF out, every step triggered by the user. One function per step; the
order lives in the client, not in the engine.

| `core_engine` function | What it does |
| --- | --- |
| `load_image(path)` | Reads a photo or scan and turns it upright, using the camera rotation the phone stored in the file. |
| `find_paper(img)` | Finds the sheet in a photo: the box to cut to, its four corners, and which pixels are paper. |
| `deskew(img, corners)` | Pulls those four corners into a rectangle, so a sheet photographed at an angle comes out as if seen from straight above. |
| `suggest_straightening(img)` | Reads the lines of writing and says how crooked they are. Needs neither the corners nor the sheet. |
| `straighten(img, degrees)` | Turns the picture by that much, cutting in slightly so no empty corners are left. |
| `suggest_levels(img)` | Measures where the paper and the writing sit, and proposes a brightness stretch. Measures the sheet only, not the table around it. |
| `apply_levels(img, l)` | Carries out that stretch: paper becomes white, writing black, colour cast gone. |
| `sharpen(img, r, t)` | Makes edges crisper. |
| `rotate(img, degrees)` | Quarter turns. |
| `crop(img, x, y, w, h)` | Cuts to the box the user drew. Refuses a box that does not fit. |
| `to_grayscale(img)` | Drops the colour. |
| `images_to_pdf(imgs, out)` | One page per image, A4, orientation follows the image, JPEG-compressed inside. |

The `backend-core-runner` crate drives all of it from the command line, which is the
same flow a graphical client will follow. Nothing runs by itself: every tool is asked
for, and `--scan` is only shorthand for the four that a photo of a document usually
wants.

```sh
cargo run -p backend-core-runner -- photo.jpg -o out.pdf --scan
```

### iPhone HEIC files
An iPhone stores photos as HEIC, which is video compression (HEVC) in a
still-image container. Decoding it means shipping an HEVC decoder, and that
carries patent licensing this project has no reason to take on - while every
target platform already has a licensed decoder installed. So HEIC handling sits
in the client, not in the engine: on macOS the runner hands the file to the
system and gets a plain image back. Other platforms will do the same with their
own decoder.

### Straightening a photo taken at an angle
A photo held over a document is a trapezoid: the near edge of the sheet is wider
than the far one. Undoing that looks like tilting the sheet in space, and it is
the one step that sounds like it needs to know how far away things were. It does
not. A flat surface seen from two positions is always related by a single 3x3
matrix, and the four corners of the sheet pin that matrix down exactly - which is
why it works from one photo, with no depth information at all.

Each pixel of the finished rectangle is worked out backwards, asking where it came
from in the photo, and read from between the four pixels around that spot. Going
forwards would leave holes wherever the stretch pulls pixels apart.

It costs about a tenth of the sharpness, because resampling always does. Sharpening
afterwards gets that back.

### Not built yet
The C FFI wrapper, the native clients, and live camera input. The engine functions
above are the pieces those will call.

Two limits are worth knowing, and both now have half an answer.

Finding the sheet goes by brightness, so it assumes the paper is brighter than what
it lies on. A document on a white desk breaks that, and so does a sheet that runs off
the edge of the photo: its outermost points are where the paper leaves the frame, not
corners of the paper, and straightening by them bends the picture instead. The engine
reports both cases rather than guessing, and a user can place the four corners
by hand - which is why `deskew` takes them as an argument instead of looking for them.

`suggest_straightening` covers the rest, because it asks the writing rather than the
paper. It finds the angle by reading the picture along slanted lines and keeping the
angle where the lines of text fall into their own rows most sharply, so it works with
no sheet found at all. What it cannot do is perspective: it only turns the picture. On
a photo taken at a real angle it is the second best answer, and on one where the
corners cannot be had it is the only one.

### Phase II & III
Future phases will build upon this manual, user-guided model by adding features like metadata and batch processing *if explicitly requested* by the user in the UI flow.

***
*For a detailed technical breakdown of how this architecture uses C FFI across Kotlin and Swift, please review the [Technical Architecture Guide](./technical_architecture.md).*
