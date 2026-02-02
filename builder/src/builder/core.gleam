import builder/asset
import builder/context
import gleam/list
import gleam/string

/// A builder processes source files and generates output
///
/// SingleFileBuilder processes each matching file individually.
/// MultipleFilesBuilder processes all matching files together in one batch.
pub type Builder {
  SingleFileBuilder(
    extensions: List(String),
    build: fn(context.BuildContext, asset.BuildAsset) -> Nil,
  )
  MultipleFilesBuilder(
    extensions: List(String),
    build: fn(context.BuildContext, List(asset.BuildAsset)) -> Nil,
  )
}

@internal
pub fn run_builders(
  builders: List(Builder),
  build_context: context.BuildContext,
  file_paths: List(String),
) -> Nil {
  let single_builders =
    list.filter_map(builders, fn(builder) {
      case builder {
        SingleFileBuilder(..) -> Ok(builder)
        MultipleFilesBuilder(..) -> Error(Nil)
      }
    })

  let multiple_builders =
    list.filter_map(builders, fn(builder) {
      case builder {
        SingleFileBuilder(..) -> Error(Nil)
        MultipleFilesBuilder(..) -> Ok(builder)
      }
    })

  list.map(multiple_builders, fn(builder) {
    case builder {
      SingleFileBuilder(..) -> Nil
      MultipleFilesBuilder(build:, ..) ->
        build(
          build_context,
          list.filter(file_paths, match_builder_patern(builder, _))
            |> list.map(asset.new_build_asset),
        )
    }
  })

  list.map(file_paths, fn(file) {
    list.map(single_builders, fn(builder) {
      case match_builder_patern(builder, file) {
        True ->
          case builder {
            SingleFileBuilder(build:, ..) -> {
              build(build_context, asset.new_build_asset(file))
            }
            MultipleFilesBuilder(..) -> Nil
          }
        _ -> Nil
      }
    })
  })

  Nil
}

fn match_builder_patern(builder: Builder, file: String) {
  case
    list.find(builder.extensions, fn(extension) {
      string.ends_with(file, extension)
    })
  {
    Ok(_) -> True
    Error(_) -> False
  }
}
