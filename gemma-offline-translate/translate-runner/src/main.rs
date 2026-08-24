//! Command line front end for the translate engine.
//!
//! It drives the same order a graphical client would: read the file, cut it into passages,
//! translate them one by one, put them back together. The engine holds the work, this file
//! only reads arguments and prints what happened.

use std::path::PathBuf;
use std::process::ExitCode;
use translate_engine::{
    load_text, rebuild_text, save_text, split_passages, translate_passage, Language, LlamaCli,
    Translator,
};

const USAGE: &str = "\
usage: gemma-translate <file.txt> --from <code> --to <code> [--model <f>] [-o <file>]

  <file.txt>          the text file to translate. Stays untouched.
  --from <code>       the language the file is in, as a two letter code
  --to <code>         the language to translate into
  --model <file>      the Gemma .gguf file on this machine.
                      Left out, the GEMMA_MODEL environment variable is used.
  --llama <file>      the llama-cli program of llama.cpp.
                      Left out, the LLAMA_CLI environment variable is used.
  -o, --output <f>    where to write the translation. Left out, it is printed.
  -h, --help          show this text

Nothing here reaches the network. The model is a file, and llama.cpp is given no
server and no address to call.
";

/// Everything the run needs, once the arguments have been read.
struct Wish {
    input: PathBuf,
    output: Option<PathBuf>,
    model: PathBuf,
    program: PathBuf,
    from: Language,
    to: Language,
}

fn main() -> ExitCode {
    let args: Vec<String> = std::env::args().skip(1).collect();

    if args.is_empty() || args.iter().any(|a| a == "-h" || a == "--help") {
        println!("{USAGE}");
        return ExitCode::SUCCESS;
    }

    match read_arguments(&args).and_then(run) {
        Ok(()) => ExitCode::SUCCESS,
        Err(message) => {
            eprintln!("Error: {message}");
            ExitCode::FAILURE
        }
    }
}

/// Reads the command line.
///
/// - Parameters: `args` - the arguments, without the program name.
/// - Returns: what to do, or a sentence naming what is missing or unknown.
fn read_arguments(args: &[String]) -> Result<Wish, String> {
    let mut input: Option<PathBuf> = None;
    let mut output: Option<PathBuf> = None;
    let mut model: Option<PathBuf> = None;
    let mut program: Option<PathBuf> = None;
    let mut from: Option<String> = None;
    let mut to: Option<String> = None;

    let mut index = 0;
    while index < args.len() {
        let arg = args[index].as_str();
        // Reading the value here, once, keeps the match below to one line per option.
        let takes_value =
            matches!(arg, "--from" | "--to" | "--model" | "--llama" | "-o" | "--output");
        let value = match takes_value {
            true => args
                .get(index + 1)
                .cloned()
                .ok_or_else(|| format!("{arg} needs a value after it."))?,
            false => String::new(),
        };
        match arg {
            "--from" => from = Some(value),
            "--to" => to = Some(value),
            "--model" => model = Some(PathBuf::from(value)),
            "--llama" => program = Some(PathBuf::from(value)),
            "-o" | "--output" => output = Some(PathBuf::from(value)),
            _ if arg.starts_with('-') => return Err(format!("{arg} is not an option I know.")),
            _ if input.is_none() => input = Some(PathBuf::from(arg)),
            _ => {
                return Err(format!(
                    "There is already a file to translate, so {arg} is one too many."
                ))
            }
        }
        index += if takes_value { 2 } else { 1 };
    }

    Ok(Wish {
        input: input.ok_or("Name the text file to translate.")?,
        output,
        model: from_argument_or_environment(model, "GEMMA_MODEL", "--model")?,
        program: from_argument_or_environment(program, "LLAMA_CLI", "--llama")?,
        from: Language::from_code(&from.ok_or("Say which language the file is in, with --from.")?)?,
        to: Language::from_code(&to.ok_or("Say which language to translate into, with --to.")?)?,
    })
}

/// Takes a path from the command line, or from the environment when the flag was left out.
fn from_argument_or_environment(
    given: Option<PathBuf>,
    variable: &str,
    flag: &str,
) -> Result<PathBuf, String> {
    if let Some(path) = given {
        return Ok(path);
    }
    std::env::var(variable)
        .map(PathBuf::from)
        .map_err(|_| format!("Say where the file is, with {flag} or the {variable} variable."))
}

/// Does the work, one step at a time, and says on the error stream where it is.
fn run(wish: Wish) -> Result<(), String> {
    let model = LlamaCli::new(&wish.program, &wish.model)?;
    let document = split_passages(&load_text(&wish.input)?);
    let count = document.passages.len();
    if count == 0 {
        return Err(format!("There is no text in {}.", wish.input.display()));
    }

    let mut translations = Vec::with_capacity(count);
    for (number, passage) in document.passages.iter().enumerate() {
        eprintln!("Passage {} of {count} ...", number + 1);
        translations.push(translate_one(&model, &passage.text, &wish, number + 1)?);
    }

    let text = rebuild_text(&document, &translations)?;
    match &wish.output {
        Some(path) => {
            save_text(&text, path)?;
            eprintln!("Wrote {}", path.display());
        }
        None => print!("{text}"),
    }
    Ok(())
}

/// Translates one passage and puts its number into the error, so a person knows where in a
/// long file the run stopped.
fn translate_one(
    model: &dyn Translator,
    passage: &str,
    wish: &Wish,
    number: usize,
) -> Result<String, String> {
    translate_passage(model, passage, &wish.from, &wish.to)
        .map_err(|why| format!("Passage {number} was not translated. {why}"))
}
