# Sara 🦑

Sara is a **serialization code generator** for Gleam.

## Sara/JSON

With the JSON module of ***Sara*** you can with the help of `//@json_encode()` and `//@json_decode()` generates type-safe JSON encoding and decoding functions for your Gleam custom types at build time.

### 1. Annotate Your Types

Add `//@json_encode()` and/or `//@json_decode()` attributes to the types you want to serialize:

```gleam
//@json_encode()
//@json_decode()
pub type Comment {
  Comment(id: Int, message: String)
}

//@json_encode()
//@json_decode()
pub type Post {
  PostWithoutComment(
    id: Int,
    title: String,
  )
  PostWithComment(
    id: Int,
    title: String,
    comments: List(Comment),
  )
}
```

### 2. Create a Build Runner

Create a new gleam project inside your existing project `gleam new build_runner`

Install both `sara` and `builder` modules. (Not dev dependencies)

Edit your build runner entry point (here build_runner.gleam)
```gleam
import builder
import sara/json

pub fn main() -> Nil {
  builder.execute_builders([
    json.json_serializable_builder(json.Config([])),
  ])
}
```

And lastly make the project you want to use `sara` depend on your `build_runner` project
```toml
[dev-dependencies]
build_runner = { path = "./build_runner" }
```

### 3. Run the Code Generator

Execute the build runner to generate the JSON serialization code:

```bash
gleam run -m build_runner
```

Or use watch mode for continuous regeneration during development:

```bash
gleam run -m build_runner watch
```

This will generate files like `entity_json.gleam` with the encoding and decoding functions.

### 4. Use the Generated Functions

Import and use the generated functions in your application:

```gleam
import entity/post
import entity/post_json
import entity/comment
import gleam/json
import gleam/io

pub fn main() -> Nil {
  let post = post.PostWithComment(
    id: 42,
    title: "Hello Sara",
    created_at: timestamp.system_time(),
    comments: [
      comment.Comment(id: 1, message: "Great post!"),
    ],
  )

  let json_string = post_json.post_to_json(post) |> json.to_string()
  io.println(json_string)

  let parsed = json.parse(json_string, post_json.post_json_decoder())
  case parsed {
    Ok(decoded_post) -> io.println("Successfully decoded!")
    Error(_) -> io.println("Failed to decode")
  }
}
```

(See the example directory at the root of this repository)

## Writing Custom Codecs

For types that require special serialization logic (like timestamps), sara/json need you to define custom codecs in its config.

### Example: Timestamp Custom Codec

Here's how to create a custom codec for the `Timestamp` type from `gleam/time`:

```gleam
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
```
