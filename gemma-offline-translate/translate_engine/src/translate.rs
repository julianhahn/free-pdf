//! The one step that turns a passage into its translation.

use crate::language::Language;
use crate::model::Translator;
use crate::prompt::{build_prompt, read_reply};

/// Translates one passage.
///
/// - Parameters: `model` - who answers. `passage` - the text, as `split_passages` cut it.
///   `from` and `to` - the two languages.
/// - Returns: the translation, or a sentence saying what stood in the way.
pub fn translate_passage(
    model: &dyn Translator,
    passage: &str,
    from: &Language,
    to: &Language,
) -> Result<String, String> {
    if passage.trim().is_empty() {
        return Err("There is nothing to translate in this passage.".to_string());
    }
    if from == to {
        return Err(format!(
            "The text is already in {}, so there is nothing to translate.",
            to.name()
        ));
    }
    let reply = model.answer(&build_prompt(passage, from, to))?;
    read_reply(&reply)
}
