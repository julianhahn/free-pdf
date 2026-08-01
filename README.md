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

1.  **User Step 1: Photo Input (Client UI)**
    *   Action: User selects or captures the raw photo.
    *   Engine Interaction: `load_photo(path)`

2.  **User Step 2: Image Enhancement Tooling (Core Engine Modules)**
    The client must present a sequential menu to the user, calling specific Rust functions for each refinement:
    a. **Perspective Correction / Deskewing:** The user clicks "Straighten," and the engine outputs an intermediate image path/buffer.
    b. **Color Correction:** The user adjusts contrast sliders (UI sends parameters) $\rightarrow$ Engine applies filters $\rightarrow$ New intermediate path/buffer.
    c. **Cropping & Detection:** The user draws a box, or clicks "Auto-Detect," passing coordinates to the engine to crop the image.

3.  **User Step 3: Final Output (Core Engine)**
    *   Action: User confirms all steps are complete $\rightarrow$ Engine receives the final processed path/buffer.
    *   Output: `convert_processed_photo_to_pdf(final_path)`

### Phase II & III
Future phases will build upon this manual, user-guided model by adding features like metadata and batch processing *if explicitly requested* by the user in the UI flow.

***
*For a detailed technical breakdown of how this architecture uses C FFI across Kotlin and Swift, please review the [Technical Architecture Guide](./technical_architecture.md).*