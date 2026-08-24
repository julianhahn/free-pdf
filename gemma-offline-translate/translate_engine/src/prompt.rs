//! The words the model is given, and the words it gives back.
//!
//! Both halves live here because they are one agreement: the prompt says "answer with the
//! translation and nothing else", and `read_reply` is what holds the model to it.

use crate::language::Language;

/// Gemma reads a conversation, not plain text. These are the marks that say whose turn it
/// is; without them the model carries on writing the instruction instead of following it.
const TURN_START: &str = "<start_of_turn>";
const TURN_END: &str = "<end_of_turn>";

/// The text to translate is fenced, so a document that itself asks a question cannot be
/// read as part of the instruction.
const FENCE: &str = "---";

/// Marks a model may print around its answer. They are deleted wherever they stand.
const MARKS: &[&str] = &["<bos>", "<eos>", TURN_END];

/// Builds the prompt for one passage.
///
/// Cannot fail: an empty passage is refused earlier, by `translate_passage`.
pub fn build_prompt(passage: &str, from: &Language, to: &Language) -> String {
    format!(
        "{TURN_START}user\n\
         Translate the text between the two {FENCE} lines from {} to {}.\n\
         Keep the line breaks. Translate every line, and translate nothing else.\n\
         Answer with the translation only: no note, no explanation, no {FENCE} lines.\n\
         {FENCE}\n{}\n{FENCE}{TURN_END}\n{TURN_START}model\n",
        from.name(),
        to.name(),
        passage.trim()
    )
}

/// Takes the model's answer apart and keeps the translation.
///
/// - Parameters: `reply` - everything the model wrote.
/// - Returns: the translation, or a sentence saying the model answered with nothing.
pub fn read_reply(reply: &str) -> Result<String, String> {
    let mut text = reply.trim().to_string();
    // A model that prints its own turn mark writes the answer before it, and whatever
    // follows is the start of a turn nobody asked for.
    if let Some(cut) = text.find(TURN_END) {
        text.truncate(cut);
    }
    for mark in MARKS {
        text = text.replace(mark, "");
    }
    let mut lines: Vec<&str> = text.lines().map(str::trim_end).collect();
    // A fence at either edge is the model copying the prompt back. One in the middle may
    // belong to the document itself, so it stays.
    while lines.first().is_some_and(|line| line.trim() == FENCE) {
        lines.remove(0);
    }
    while lines.last().is_some_and(|line| line.trim() == FENCE) {
        lines.pop();
    }
    let text = lines.join("\n").trim().to_string();
    if text.is_empty() {
        return Err(
            "The model answered with nothing, so this passage has no translation yet.".to_string()
        );
    }
    Ok(text)
}
