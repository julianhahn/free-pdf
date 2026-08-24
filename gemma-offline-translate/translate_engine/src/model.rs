//! Where the answer comes from.
//!
//! The engine never speaks to a model itself. It asks whatever is behind `Translator`, so
//! a test can answer without a model file and a client can swap the runner later without
//! touching a single step above this line.

use std::path::{Path, PathBuf};
use std::process::Command;

/// Anything that can answer a prompt.
pub trait Translator {
    /// Answers one prompt.
    ///
    /// - Parameters: `prompt` - what `build_prompt` built.
    /// - Returns: everything the model wrote, or a sentence saying why it wrote nothing.
    fn answer(&self, prompt: &str) -> Result<String, String>;
}

/// How much room the answer gets, counted in tokens per character of the prompt. One
/// token is about four characters, so this is roughly four times what a translation needs.
/// Generous on purpose: a ceiling that is too low cuts the last sentence off silently.
const ANSWER_TOKENS_PER_CHARACTER: usize = 1;

/// Never fewer than this, so a two word passage still has room for punctuation.
const LEAST_ANSWER_TOKENS: usize = 64;

/// A Gemma model in a local file, run by the `llama-cli` program of llama.cpp.
///
/// Both paths are files on this machine and llama.cpp is given no server and no URL, so a
/// translation cannot reach the network even when the machine is online.
#[derive(Debug)]
pub struct LlamaCli {
    program: PathBuf,
    model: PathBuf,
}

impl LlamaCli {
    /// Points the engine at the program and the model file.
    ///
    /// - Parameters: `program` - the `llama-cli` binary. `model` - the `.gguf` model file.
    /// - Returns: the translator, or a sentence naming the path that is not there.
    pub fn new(program: &Path, model: &Path) -> Result<Self, String> {
        if !program.is_file() {
            return Err(format!(
                "There is no llama-cli program at {}. Build llama.cpp first, then say where it is.",
                program.display()
            ));
        }
        if !model.is_file() {
            return Err(format!(
                "There is no model file at {}. Download a Gemma .gguf file first, then say where it is.",
                model.display()
            ));
        }
        Ok(Self { program: program.to_path_buf(), model: model.to_path_buf() })
    }
}

impl Translator for LlamaCli {
    fn answer(&self, prompt: &str) -> Result<String, String> {
        let room = (prompt.len() * ANSWER_TOKENS_PER_CHARACTER).max(LEAST_ANSWER_TOKENS);
        let run = Command::new(&self.program)
            .arg("--model")
            .arg(&self.model)
            .arg("--prompt")
            .arg(prompt)
            // -n caps the answer, -no-cnv keeps llama-cli from opening a chat and waiting
            // for a person, and --no-display-prompt leaves only the answer on stdout.
            .args(["-n", &room.to_string(), "-no-cnv", "--no-display-prompt", "--no-warmup"])
            .output()
            .map_err(|why| format!("Failed to run {}: {}", self.program.display(), why))?;
        if !run.status.success() {
            let said = String::from_utf8_lossy(&run.stderr);
            return Err(format!(
                "{} stopped without translating. It said: {}",
                self.program.display(),
                said.lines().last().unwrap_or("nothing").trim()
            ));
        }
        String::from_utf8(run.stdout)
            .map_err(|_| "The model answered with bytes that are not text.".to_string())
    }
}
