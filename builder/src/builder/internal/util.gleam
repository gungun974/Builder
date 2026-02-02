import filepath
import gleam/list
import gleam/string
import simplifile

pub fn find_current_project_root_path() -> String {
  let assert Ok(current_directory) = simplifile.current_directory()
    as "current directory couldn't be fetched"
  find_project_root_path(current_directory)
}

pub fn find_project_root_path(path: String) -> String {
  find_project_root_path_loop(path)
}

fn find_project_root_path_loop(path: String) -> String {
  case path {
    "" -> {
      panic as "gleam project directory couldn't be found"
    }
    _ ->
      case simplifile.is_file(filepath.join(path, "gleam.toml")) {
        Ok(True) -> path
        _ -> find_project_root_path_loop(filepath.directory_name(path))
      }
  }
}

pub fn scan_walk(path: String) -> List(String) {
  assert filepath.is_absolute(path)
    as "scan_walk should always start with a absolute path"

  case simplifile.is_file(path) {
    Ok(True) -> {
      [path]
    }

    _ -> {
      let paths = case simplifile.read_directory(path) {
        Ok(files) -> files
        Error(simplifile.Enoent) -> []
        Error(_) -> panic as { "couldn't read directory: " <> path }
      }

      list.flat_map(paths, fn(name) { scan_walk(filepath.join(path, name)) })
    }
  }
}

pub fn trim_prefix(string: String, prefix: String) -> String {
  case string.starts_with(string, prefix) {
    True -> string.drop_start(string, string.length(prefix))
    False -> string
  }
}

pub fn trim_sufix(string: String, prefix: String) -> String {
  case string.ends_with(string, prefix) {
    True -> string.drop_end(string, string.length(prefix))
    False -> string
  }
}
