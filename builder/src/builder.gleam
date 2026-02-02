import argv
import builder/asset
import builder/context
import builder/core.{type Builder, MultipleFilesBuilder, SingleFileBuilder}
import builder/internal/analyzer
import builder/internal/util
import filepath
import gleam/dict
import gleam/erlang/process
import gleam/io
import gleam/list
import gleam/otp/static_supervisor
import gleam/result
import polly

/// Execute a build function on each files matching the source extensions
pub fn new_generic_builder(
  source_extensions: List(String),
  build: fn(context.BuildContext, asset.BuildAsset) -> Nil,
) {
  SingleFileBuilder(extensions: source_extensions, build:)
}

/// Execute a unique build function on multiple files in one step
pub fn new_generic_multiple_builder(
  source_extensions: List(String),
  build: fn(context.BuildContext, List(asset.BuildAsset)) -> Nil,
) {
  MultipleFilesBuilder(extensions: source_extensions, build:)
}

/// Execute a build function on every gleam files
pub fn new_gleam_builder(
  build: fn(context.BuildContext, asset.GleamAsset) -> Nil,
) {
  new_generic_builder(["gleam"], fn(ctx, file) {
    let modules = dict.to_list(context.modules(ctx))

    case
      list.find_map(modules, fn(entry) {
        let module = entry.1
        case module.file == file.path {
          True -> Ok(module)
          False -> Error(Nil)
        }
      })
      |> result.map(fn(module) { asset.GleamBuildAsset(module:, file:) })
    {
      Ok(asset) -> build(ctx, asset)
      Error(_) -> Nil
    }
  })
}

/// Execute a unique build function on multiple files
pub fn new_gleam_multiple_builder(
  build: fn(context.BuildContext, List(asset.GleamAsset)) -> Nil,
) {
  new_generic_multiple_builder(["gleam"], fn(ctx, files) {
    let modules = dict.to_list(context.modules(ctx))

    build(
      ctx,
      list.filter_map(files, fn(file) {
        list.find_map(modules, fn(entry) {
          let module = entry.1
          case module.file == file.path {
            True -> Ok(module)
            False -> Error(Nil)
          }
        })
        |> result.map(fn(module) { asset.GleamBuildAsset(module:, file:) })
      }),
    )
  })
}

/// Execute the provided list of builders
///
/// When run with the "watch" argument, starts a file watcher that continuously
/// monitors the source directory and rebuilds on changes. Otherwise, performs
/// a single build pass.
pub fn execute_builders(builders: List(Builder)) -> Nil {
  case argv.load().arguments {
    ["watch", ..] -> watch_builders(builders)
    _ -> process_builders(builders)
  }

  Nil
}

fn watch_builders(builders: List(Builder)) -> Nil {
  io.println("Start builders watcher")

  let source_directory =
    filepath.join(util.find_current_project_root_path(), "src")

  let watcher =
    polly.new()
    |> polly.add_dir(source_directory)
    |> polly.interval(100)
    |> polly.add_callback(fn(event) {
      case event {
        polly.Changed(_) -> process_builders(builders)
        polly.Created(_) -> process_builders(builders)
        polly.Deleted(_) -> process_builders(builders)
        polly.Error(_, _) -> Nil
      }
    })
    |> polly.supervised

  let assert Ok(_) =
    static_supervisor.new(static_supervisor.OneForOne)
    |> static_supervisor.add(watcher)
    |> static_supervisor.start

  process.sleep_forever()

  Nil
}

fn process_builders(builders: List(Builder)) -> Nil {
  io.println("Process builders")

  let source_directory =
    filepath.join(util.find_current_project_root_path(), "src")

  let files = util.scan_walk(source_directory)

  let project_modules = analyzer.analyze_project(source_directory)

  let build_context = context.new_build_context(project_modules)

  core.run_builders(builders, build_context, files)

  Nil
}
