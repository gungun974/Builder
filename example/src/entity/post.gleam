import entity/comment
import gleam/option.{type Option}
import gleam/time/timestamp.{type Timestamp}

pub type Content =
  String

//@json_encode()
//@json_decode()
pub type Post {
  PostWithoutComment(
    id: Int,
    title: String,
    content: Content,
    created_at: Timestamp,
    updated_at: Option(Timestamp),
    score: Score,
  )
  PostWithComment(
    id: Int,
    title: String,
    content: Content,
    created_at: Timestamp,
    updated_at: Option(Timestamp),
    score: Score,
    comments: List(comment.Comment),
  )
}

//@json_encode()
//@json_decode()
pub type Score {
  Good
  Bad
  Custom(Int)
}
