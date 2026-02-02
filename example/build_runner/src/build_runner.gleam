import builder
import sara/json

pub fn main() -> Nil {
  builder.execute_builders([
    json.json_serializable_builder(
      json.Config([
        json.CustomCodec(
          type_name: "Timestamp",
          module_path: "gleam/time/timestamp",
          encode: fn(_, _, variable, _, _) {
            json.GeneratedCode(
              "json.string(timestamp.to_rfc3339("
                <> variable
                <> ", calendar.utc_offset))",
              ["gleam/time/calendar", "gleam/time/timestamp"],
              [],
            )
          },
          decode: fn(_, _, _, _) {
            json.GeneratedCode(
              "{
  use date <- decode.then(decode.string)
  case timestamp.parse_rfc3339(date) {
    Ok(timestamp) -> decode.success(timestamp)
    Error(_) -> decode.failure(timestamp.system_time(), \"Timestamp\")
  }
}",
              ["gleam/time/calendar", "gleam/time/timestamp"],
              [],
            )
          },
          zero: fn(_, _, _, _) {
            Ok(
              json.GeneratedCode(
                "timestamp.system_time()",
                ["gleam/time/timestamp"],
                [],
              ),
            )
          },
        ),
      ]),
    ),
  ])
}
