# Technical Deep Dive: Cross-Platform FFI Architecture
**File:** `free-pdf/technical_architecture.md`

## 🌉 The C Foreign Function Interface (FFI) Explained
The FreePDF Suite relies entirely on the **Foreign Function Interface (FFI)** to achieve its goal of operating as a single, unified system across vastly different native environments (iOS Swift, Android Kotlin, Windows C++).

### What is FFI?
The FFI is not a feature implemented by one language; it is a *concept* that allows a program written in Language A to execute functions compiled for Language B. By using Rust as the central engine, we compile our complex logic into a **Shared Library** (e.g., `.so` on Linux, `.dylib` on macOS, `.dll` on Windows).

### The Three Pillars of Our Architecture
1.  **Rust (`core_engine`):** Acts as the API provider. It is the *only* place where the business logic resides and where C-compatible signatures are enforced using `extern "C"` blocks and `#[no_mangle]`. This guarantees stability for all clients.
2.  **Client Languages (Kotlin/Swift/C++/etc.):** These languages act purely as **UI consumers**. They do not know *how* the PDF conversion happens; they only know that if they call function `convertPhotoToPdf(path1, path2)`, they will get a specific boolean status code back.
3.  **The Bridge (FFI):** This is the runtime mechanism. Each client language uses its native tools (JNI for Kotlin, Linking/Bridging Headers for Swift) to load the compiled Rust shared library and call the exposed functions by their exact C-compatible name signature.

### ⚙️ Flow Example: Photo $\rightarrow$ PDF
1.  **Kotlin:** Calls `convertPhotoToPdf("img.jpg", "out.pdf")` in its UI code.
2.  **JNI Layer (Adapter):** Intercepts the Kotlin call and translates it into raw memory pointers (`*const char`).
3.  **C ABI Call:** Passes these raw pointers to `_core_engine_convert_photo_to_pdf_ffi()`.
4.  **Rust Core:** Receives the pointers, converts them back to safe Rust strings, executes the logic (Image Load $\rightarrow$ PDF Write), and returns an integer status code (0 for success).

### ⚠️ Implementation Requirements & Caveats
*   **Strict Signature Matching:** The function name, parameter types, and return type in the C/Rust layer *must* exactly match what is declared by the client side.
*   **Memory Management:** Handing memory across language boundaries (e.g., Rust generating a large image buffer that Kotlin needs to read) requires extreme care using raw pointers (`*const char`) or specialized resource managers.

*(This detailed understanding of FFI allows us to write safer, more performant cross-platform code.)*
