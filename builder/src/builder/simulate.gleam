import builder/asset.{type BuildAsset}
import builder/context.{type BuildContext}
import builder/core.{type Builder}
import builder/internal/analyzer
import builder/internal/util
import filepath
import gleam/dict
import gleam/list
import gleam/option.{None, Some}
import gleam/result

type VirtualModule {
  VirtualModule(
    contents: String,
    module_path: String,
    package_name: String,
    path: String,
  )
}

fn create_virtal_modules(modules: List(VirtualModule)) {
  list.try_map(modules, fn(module) {
    analyzer.analyze_module_contents(
      module.contents,
      module.module_path,
      module.package_name,
      module.path,
    )
  })
  |> result.map(fn(modules) {
    list.map(modules, fn(module) { #(module.path, module) }) |> dict.from_list
  })
}

/// Represents a virtual file in memory for testing
pub type VirtualFile {
  VirtualFile(path: String, contents: String)
}

/// Run builders in a simulated environment for testing purposes only
///
/// Creates a virtual build context with in-memory files instead of touching
/// the real file system. Useful for unit testing builders without side effects.
pub fn simulate_builder_run(
  builders builders: List(Builder),
  project_files project_files: List(VirtualFile),
  read read: fn(BuildContext, BuildAsset) ->
    Result(option.Option(String), context.Error),
  read_bits read_bits: fn(BuildContext, BuildAsset) ->
    Result(option.Option(BitArray), context.Error),
  write write: fn(BuildContext, BuildAsset, String) ->
    Result(Nil, context.Error),
  write_bits write_bits: fn(BuildContext, BuildAsset, BitArray) ->
    Result(Nil, context.Error),
) -> Nil {
  let file_paths = project_files |> list.map(fn(file) { file.path })

  let assert Ok(project_modules) =
    create_virtal_modules(
      project_files
      |> list.filter_map(fn(file) {
        case filepath.extension(file.path) == Ok("gleam") {
          True ->
            Ok(VirtualModule(
              contents: file.contents,
              module_path: util.trim_prefix(file.path, "/")
                |> filepath.strip_extension,
              package_name: "simulated",
              path: file.path,
            ))
          _ -> Error(Nil)
        }
      }),
    )

  let build_context =
    context.new_dummy_build_context(
      project_modules,
      fn(ctx, asset) {
        case read(ctx, asset) {
          Ok(None) -> todo
          Ok(Some(val)) -> Ok(val)
          Error(err) -> Error(err)
        }
      },
      fn(ctx, asset) {
        case read_bits(ctx, asset) {
          Ok(None) -> todo
          Ok(Some(val)) -> Ok(val)
          Error(err) -> Error(err)
        }
      },
      fn(ctx, asset, contents) { write(ctx, asset, contents) },
      fn(ctx, asset, bits) { write_bits(ctx, asset, bits) },
    )

  core.run_builders(builders, build_context, file_paths)

  Nil
}
