import entity/comment_json
import entity/post
import gleam/dynamic/decode
import gleam/json
import gleam/option
import gleam/time/calendar
import gleam/time/timestamp

pub fn post_to_json(post: post.Post) -> json.Json {
  case post {
    post.PostWithoutComment(
      id:,
      title:,
      content:,
      created_at:,
      updated_at:,
      score:,
    ) ->
      json.object([
        #("type", json.string("post_without_comment")),
        #("id", json.int(id)),
        #("title", json.string(title)),
        #("content", json.string(content)),
        #(
          "created_at",
          json.string(timestamp.to_rfc3339(created_at, calendar.utc_offset)),
        ),
        #("updated_at", case updated_at {
          option.None -> json.null()
          option.Some(x) ->
            json.string(timestamp.to_rfc3339(x, calendar.utc_offset))
        }),
        #("score", score_to_json(score)),
      ])

    post.PostWithComment(
      id:,
      title:,
      content:,
      created_at:,
      updated_at:,
      score:,
      comments:,
    ) ->
      json.object([
        #("type", json.string("post_with_comment")),
        #("id", json.int(id)),
        #("title", json.string(title)),
        #("content", json.string(content)),
        #(
          "created_at",
          json.string(timestamp.to_rfc3339(created_at, calendar.utc_offset)),
        ),
        #("updated_at", case updated_at {
          option.None -> json.null()
          option.Some(x) ->
            json.string(timestamp.to_rfc3339(x, calendar.utc_offset))
        }),
        #("score", score_to_json(score)),
        #(
          "comments",
          json.array(comments, fn(x) { comment_json.comment_to_json(x) }),
        ),
      ])
  }
}

pub fn score_to_json(score: post.Score) -> json.Json {
  case score {
    post.Good ->
      json.object([
        #("type", json.string("good")),
      ])

    post.Bad ->
      json.object([
        #("type", json.string("bad")),
      ])

    post.Custom(field0) ->
      json.object([
        #("type", json.string("custom")),
        #("field0", json.int(field0)),
      ])
  }
}

pub fn post_json_decoder() -> decode.Decoder(post.Post) {
  use variant <- decode.field("type", decode.string)
  case variant {
    "post_without_comment" -> {
      use id <- decode.field("id", decode.int)
      use title <- decode.field("title", decode.string)
      use content <- decode.field("content", decode.string)
      use created_at <- decode.field("created_at", {
        use date <- decode.then(decode.string)
        case timestamp.parse_rfc3339(date) {
          Ok(timestamp) -> decode.success(timestamp)
          Error(_) -> decode.failure(timestamp.system_time(), "Timestamp")
        }
      })
      use updated_at <- decode.field(
        "updated_at",
        decode.optional({
          use date <- decode.then(decode.string)
          case timestamp.parse_rfc3339(date) {
            Ok(timestamp) -> decode.success(timestamp)
            Error(_) -> decode.failure(timestamp.system_time(), "Timestamp")
          }
        }),
      )
      use score <- decode.field("score", score_json_decoder())
      decode.success(post.PostWithoutComment(
        id:,
        title:,
        content:,
        created_at:,
        updated_at:,
        score:,
      ))
    }
    "post_with_comment" -> {
      use id <- decode.field("id", decode.int)
      use title <- decode.field("title", decode.string)
      use content <- decode.field("content", decode.string)
      use created_at <- decode.field("created_at", {
        use date <- decode.then(decode.string)
        case timestamp.parse_rfc3339(date) {
          Ok(timestamp) -> decode.success(timestamp)
          Error(_) -> decode.failure(timestamp.system_time(), "Timestamp")
        }
      })
      use updated_at <- decode.field(
        "updated_at",
        decode.optional({
          use date <- decode.then(decode.string)
          case timestamp.parse_rfc3339(date) {
            Ok(timestamp) -> decode.success(timestamp)
            Error(_) -> decode.failure(timestamp.system_time(), "Timestamp")
          }
        }),
      )
      use score <- decode.field("score", score_json_decoder())
      use comments <- decode.field(
        "comments",
        decode.list(comment_json.comment_json_decoder()),
      )
      decode.success(post.PostWithComment(
        id:,
        title:,
        content:,
        created_at:,
        updated_at:,
        score:,
        comments:,
      ))
    }
    _ ->
      decode.failure(
        post.PostWithoutComment(
          id: 0,
          title: "",
          content: "",
          created_at: timestamp.system_time(),
          updated_at: option.None,
          score: post.Good,
        ),
        "Post",
      )
  }
}

pub fn score_json_decoder() -> decode.Decoder(post.Score) {
  use variant <- decode.field("type", decode.string)
  case variant {
    "good" -> {
      decode.success(post.Good)
    }
    "bad" -> {
      decode.success(post.Bad)
    }
    "custom" -> {
      use field0 <- decode.field("field0", decode.int)
      decode.success(post.Custom(field0))
    }
    _ -> decode.failure(post.Good, "Score")
  }
}
