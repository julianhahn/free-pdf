//! The two languages a translation runs between.
//!
//! The model is asked in English words ("German"), not in codes, because a code in the
//! prompt makes some models answer with the code instead of the language.

/// Every language this tool takes, as `(code, English name)`.
///
/// The list is short on purpose: a code that is in here has been read out loud in a prompt
/// and answered correctly. Adding one is a one-line change plus a look at the result.
pub const KNOWN_LANGUAGES: &[(&str, &str)] = &[
    ("de", "German"),
    ("en", "English"),
    ("fr", "French"),
    ("es", "Spanish"),
    ("it", "Italian"),
    ("nl", "Dutch"),
    ("pl", "Polish"),
    ("pt", "Portuguese"),
    ("tr", "Turkish"),
    ("uk", "Ukrainian"),
];

/// One side of a translation: the code a person types and the word the model reads.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Language {
    code: String,
    name: String,
}

impl Language {
    /// Turns a language code into a language.
    ///
    /// - Parameters: `code` - a two letter code, upper or lower case, such as `de`.
    /// - Returns: the language, or a sentence naming the code and listing the ones that work.
    pub fn from_code(code: &str) -> Result<Self, String> {
        let wanted = code.trim().to_lowercase();
        for (known, name) in KNOWN_LANGUAGES {
            if *known == wanted {
                return Ok(Self { code: (*known).to_string(), name: (*name).to_string() });
            }
        }
        let all: Vec<&str> = KNOWN_LANGUAGES.iter().map(|(c, _)| *c).collect();
        Err(format!("\"{}\" is not a language this tool knows. It knows {}.", code, all.join(", ")))
    }

    /// The code the language was named by, lower case.
    pub fn code(&self) -> &str {
        &self.code
    }

    /// The English name of the language, which is what goes into the prompt.
    pub fn name(&self) -> &str {
        &self.name
    }
}
