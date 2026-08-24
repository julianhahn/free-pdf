//! Translate a text file on the machine it sits on, with a Gemma model in a local file.
//!
//! Every step is its own function, so a client can skip one, redo it, or let a person
//! correct the result in between. Nothing runs by itself.

mod document;
mod language;
mod model;
mod prompt;
mod translate;

pub use document::{load_text, rebuild_text, save_text, split_passages, Document, Passage};
pub use language::{Language, KNOWN_LANGUAGES};
pub use model::{LlamaCli, Translator};
pub use prompt::{build_prompt, read_reply};
pub use translate::translate_passage;
