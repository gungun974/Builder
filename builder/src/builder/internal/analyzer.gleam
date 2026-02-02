import builder/internal/superglance
import builder/internal/util
import builder/module.{type Module, Module}
import filepath
import glance
import gleam/dict.{type Dict}
import gleam/list
import gleam/result
import simplifile
import tom

pub type Error {
  FailedToReadFile(simplifile.FileError)
  FailedToParse(glance.Error)
  FailedToParseProjectToml(tom.ParseError)
}

pub fn analyze_module_file(path: String) -> Result(Module, Error) {
  use contents <- result.try(
    simplifile.read(path)
    |> result.map_error(fn(x) { FailedToReadFile(x) }),
  )

  let project_root = util.find_project_root_path(path)

  use project_toml <- result.try(
    simplifile.read(filepath.join(project_root, "gleam.toml"))
    |> result.map_error(fn(x) { FailedToReadFile(x) }),
  )

  use project_info <- result.try(
    tom.parse(project_toml)
    |> result.map_error(fn(x) { FailedToParseProjectToml(x) }),
  )

  let assert Ok(package_name) = tom.get_string(project_info, ["name"])

  let src_directory = filepath.join(project_root, "src") <> "/"

  let gleam_path = filepath.strip_extension(path)

  analyze_module_contents(
    contents,
    util.trim_prefix(gleam_path, src_directory),
    package_name,
    path,
  )
}

pub fn analyze_module_contents(
  contents: String,
  module_path: String,
  package_name: String,
  path: String,
) -> Result(Module, Error) {
  use module <- result.try(
    superglance.module(contents)
    |> result.map_error(fn(x) { FailedToParse(x) }),
  )

  Ok(Module(
    name: filepath.base_name(module_path),
    package: package_name,
    path: module_path,
    imports: module.imports,
    custom_types: module.custom_types,
    type_aliases: module.type_aliases,
    constants: module.constants,
    functions: module.functions,
    external: False,
    file: path,
  ))
}

pub fn analyze_project(path: String) -> Dict(String, Module) {
  let project_root = util.find_project_root_path(path)

  let project_src = filepath.join(project_root, "src")

  let project_packages =
    project_root
    |> filepath.join("build")
    |> filepath.join("packages")

  let sources_files =
    list.filter_map(util.scan_walk(project_src), fn(file) {
      case filepath.extension(file) == Ok("gleam") {
        True -> Ok(#(file, False))
        False -> Error(Nil)
      }
    })

  let packages_files = case simplifile.is_directory(project_packages) {
    Ok(_) ->
      list.filter_map(util.scan_walk(project_packages), fn(file) {
        case filepath.extension(file) == Ok("gleam") {
          True -> Ok(#(file, True))
          False -> Error(Nil)
        }
      })
    _ -> []
  }

  let files = sources_files |> list.append(packages_files)

  let modules =
    list.map(files, fn(file) {
      use module <- result.map(analyze_module_file(file.0))
      Module(..module, external: file.1)
    })
    |> list.fold(dict.new(), fn(modules, module) {
      case module {
        Ok(module) -> {
          dict.insert(modules, module.path, module)
        }
        _ -> modules
      }
    })

  modules
}
