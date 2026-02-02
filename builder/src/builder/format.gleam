import gleam/result
import shellout.{LetBeStderr}

/// Format Gleam source code using the standard gleam formatter
///
/// Runs the code through `gleam format --stdin` and returns the formatted result.
pub fn format_gleam_code(code: String) -> Result(String, Nil) {
  shellout.command(run: "sh", with: ["-euc", "
  echo '" <> code <> "' \\
    | gleam format --stdin
"], in: ".", opt: [LetBeStderr])
  |> result.map_error(fn(_) { Nil })
}
