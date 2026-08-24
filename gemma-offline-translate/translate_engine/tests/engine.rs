//! Every test brings its own text and its own answers, so the suite needs neither a model
//! file nor llama.cpp. `LlamaCli` is the one part a test cannot reach; it is checked by
//! hand against a real build (see the README).

use std::cell::RefCell;
use translate_engine::*;

/// A model that hands back whatever the test told it to say, and remembers what it was
/// asked, so a test can look at the prompt the engine built.
struct Parrot {
    reply: String,
    heard: RefCell<Vec<String>>,
}

impl Parrot {
    fn saying(reply: &str) -> Self {
        Self { reply: reply.to_string(), heard: RefCell::new(Vec::new()) }
    }
}

impl Translator for Parrot {
    fn answer(&self, prompt: &str) -> Result<String, String> {
        self.heard.borrow_mut().push(prompt.to_string());
        Ok(self.reply.clone())
    }
}

fn german() -> Language {
    Language::from_code("de").expect("de is a known language")
}

fn english() -> Language {
    Language::from_code("en").expect("en is a known language")
}

#[test]
fn a_language_code_may_be_typed_in_any_case() {
    assert_eq!(Language::from_code("DE").unwrap(), german());
    assert_eq!(Language::from_code(" de ").unwrap().name(), "German");
}

#[test]
fn an_unknown_language_names_itself_and_the_ones_that_work() {
    let why = Language::from_code("xx").unwrap_err();
    assert!(why.contains("\"xx\""), "{why}");
    assert!(why.contains("de"), "{why}");
}

#[test]
fn passages_are_cut_at_blank_lines() {
    let document = split_passages("First one.\n\nSecond one.\n");
    assert_eq!(document.passages.len(), 2);
    assert_eq!(document.passages[0].text, "First one.");
    assert_eq!(document.passages[1].text, "Second one.");
}

#[test]
fn a_line_break_inside_a_passage_stays_inside_it() {
    let document = split_passages("Dear Sir,\nthank you for the letter.");
    assert_eq!(document.passages.len(), 1);
    assert_eq!(document.passages[0].text, "Dear Sir,\nthank you for the letter.");
}

#[test]
fn cutting_a_text_loses_no_character() {
    for text in
        ["", "\n\n", "  \n\nOne.\n\n\n\nTwo.  \n", "\tIndented.\n\nAnd more.", "Ohne Leerzeile"]
    {
        let document = split_passages(text);
        let same: Vec<String> = document.passages.iter().map(|p| p.text.clone()).collect();
        assert_eq!(rebuild_text(&document, &same).unwrap(), text, "text was {text:?}");
    }
}

#[test]
fn an_empty_text_has_no_passages() {
    assert!(split_passages("   \n  ").passages.is_empty());
}

#[test]
fn rebuilding_says_how_many_translations_it_wanted() {
    let document = split_passages("One.\n\nTwo.");
    let why = rebuild_text(&document, &["Eins.".to_string()]).unwrap_err();
    assert!(why.contains("2 passages"), "{why}");
}

#[test]
fn a_translation_takes_the_place_of_its_passage() {
    let document = split_passages("One.\n\nTwo.\n");
    let done = rebuild_text(&document, &["Eins.".to_string(), "Zwei.".to_string()]).unwrap();
    assert_eq!(done, "Eins.\n\nZwei.\n");
}

#[test]
fn the_prompt_names_both_languages_and_fences_the_text() {
    let prompt = build_prompt("Guten Tag.", &german(), &english());
    assert!(prompt.contains("from German to English"), "{prompt}");
    assert!(prompt.contains("---\nGuten Tag.\n---"), "{prompt}");
    assert!(prompt.ends_with("<start_of_turn>model\n"), "{prompt}");
}

#[test]
fn the_answer_keeps_only_the_translation() {
    assert_eq!(read_reply("  Good day.\n<end_of_turn>\n").unwrap(), "Good day.");
    assert_eq!(read_reply("---\nGood day.\n---<eos>").unwrap(), "Good day.");
    assert_eq!(read_reply("Line one.\nLine two.").unwrap(), "Line one.\nLine two.");
}

#[test]
fn an_answer_with_nothing_in_it_is_refused() {
    let why = read_reply("<end_of_turn>").unwrap_err();
    assert!(why.contains("answered with nothing"), "{why}");
}

#[test]
fn translating_asks_the_model_once_and_returns_its_words() {
    let model = Parrot::saying("Good day.<end_of_turn>");
    let done = translate_passage(&model, "Guten Tag.", &german(), &english()).unwrap();
    assert_eq!(done, "Good day.");
    assert_eq!(model.heard.borrow().len(), 1);
}

#[test]
fn an_empty_passage_is_refused_before_the_model_is_asked() {
    let model = Parrot::saying("Good day.");
    let why = translate_passage(&model, "   ", &german(), &english()).unwrap_err();
    assert!(why.contains("nothing to translate"), "{why}");
    assert!(model.heard.borrow().is_empty(), "the model was asked anyway");
}

#[test]
fn one_language_translated_into_itself_is_refused() {
    let model = Parrot::saying("Guten Tag.");
    let why = translate_passage(&model, "Guten Tag.", &german(), &german()).unwrap_err();
    assert!(why.contains("already in German"), "{why}");
}

#[test]
fn a_missing_program_says_where_it_was_looked_for() {
    let nowhere = std::path::Path::new("/no/such/llama-cli");
    let why = LlamaCli::new(nowhere, nowhere).unwrap_err();
    assert!(why.contains("/no/such/llama-cli"), "{why}");
    assert!(why.contains("llama.cpp"), "{why}");
}

#[test]
fn a_missing_model_file_says_which_path_is_empty() {
    // Any file will do as the program here; only the model path is under test.
    let program = std::env::current_exe().expect("the test binary is a file");
    let why = LlamaCli::new(&program, std::path::Path::new("/no/such/model.gguf")).unwrap_err();
    assert!(why.contains("/no/such/model.gguf"), "{why}");
    assert!(why.contains("Gemma"), "{why}");
}
