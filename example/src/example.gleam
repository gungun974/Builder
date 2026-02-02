import entity/comment
import entity/post
import entity/post_json
import gleam/io
import gleam/json
import gleam/option
import gleam/time/timestamp

pub fn main() -> Nil {
  let post =
    post.PostWithComment(
      id: 42,
      title: "Hoi Sara",
      content: "🦑",
      created_at: timestamp.system_time(),
      updated_at: option.None,
      score: post.Custom(8),
      comments: [
        comment.Comment(id: 4, message: "I LOVE TV!!"),
      ],
    )

  echo post

  let json = post_json.post_to_json(post) |> json.to_string()

  io.println(json)

  let parsed = json.parse(json, post_json.post_json_decoder())

  echo parsed

  Nil
}
