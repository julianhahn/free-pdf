//! Reading a text file, cutting it into passages, and putting the translation back.
//!
//! A translation is asked for one passage at a time: a whole file in one prompt runs past
//! what the model can hold, and one bad answer would spoil the entire text. Cutting is
//! lossless - every blank line and indent the file had is kept aside and written back - so
//! the translated file has the shape of the original.

use std::fs;
use std::path::Path;

/// One block of text and the empty space that followed it in the file.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Passage {
    /// The text to translate. Never empty and never only spaces.
    pub text: String,
    /// The line breaks and spaces that stood between this passage and the next one.
    pub gap: String,
}

/// A file cut into passages, with every character accounted for.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Document {
    /// The empty space before the first passage.
    pub opening_gap: String,
    /// The passages, in the order they stand in the file.
    pub passages: Vec<Passage>,
}

/// A passage ends where a line break follows a line that had text on it.
const PASSAGE_BREAK: &str = "\n\n";

/// Reads a text file.
///
/// - Parameters: `path` - the file to read.
/// - Returns: the text, or a sentence naming the path and what went wrong.
pub fn load_text(path: &Path) -> Result<String, String> {
    fs::read_to_string(path)
        .map_err(|why| format!("Failed to read the text from {}: {}", path.display(), why))
}

/// Writes a text file, making the folders above it if they are missing.
///
/// - Parameters: `text` - what to write. `path` - where to write it.
/// - Returns: nothing, or a sentence naming the path and what went wrong.
pub fn save_text(text: &str, path: &Path) -> Result<(), String> {
    if let Some(folder) = path.parent() {
        if !folder.as_os_str().is_empty() {
            fs::create_dir_all(folder).map_err(|why| {
                format!("Failed to make the folder {}: {}", folder.display(), why)
            })?;
        }
    }
    fs::write(path, text)
        .map_err(|why| format!("Failed to write the text to {}: {}", path.display(), why))
}

/// Cuts a text into the passages a translation is asked for one by one.
///
/// Cannot fail: a text with nothing in it becomes a document with no passages.
pub fn split_passages(text: &str) -> Document {
    let mut document = Document { opening_gap: String::new(), passages: Vec::new() };

    for (index, block) in text.split(PASSAGE_BREAK).enumerate() {
        if index > 0 {
            // The break that ended the block before this one.
            document.keep_gap(PASSAGE_BREAK);
        }
        let body = block.trim();
        if body.is_empty() {
            document.keep_gap(block);
            continue;
        }
        let front = block.len() - block.trim_start().len();
        document.keep_gap(&block[..front]);
        document.passages.push(Passage { text: body.to_string(), gap: String::new() });
        document.keep_gap(&block[front + body.len()..]);
    }

    document
}

/// Puts translated passages back into the shape the file had.
///
/// - Parameters: `document` - what `split_passages` gave. `translations` - one translation
///   per passage, in the same order.
/// - Returns: the finished text, or a sentence saying how many passages were expected.
pub fn rebuild_text(document: &Document, translations: &[String]) -> Result<String, String> {
    if translations.len() != document.passages.len() {
        return Err(format!(
            "The text has {} passages, so it needs {} translations, not {}.",
            document.passages.len(),
            document.passages.len(),
            translations.len()
        ));
    }
    let mut out = document.opening_gap.clone();
    for (passage, translation) in document.passages.iter().zip(translations) {
        out.push_str(translation.trim());
        out.push_str(&passage.gap);
    }
    Ok(out)
}

impl Document {
    /// Files away empty space so nothing is lost: it belongs to the passage before it, or
    /// to the front of the file when no passage has started yet.
    fn keep_gap(&mut self, space: &str) {
        match self.passages.last_mut() {
            Some(last) => last.gap.push_str(space),
            None => self.opening_gap.push_str(space),
        }
    }
}
