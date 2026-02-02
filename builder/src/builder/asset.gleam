import builder/module.{type Module}
import filepath

/// Represents a Gleam source file asset with its associated module information
pub type GleamAsset {
  GleamBuildAsset(module: Module, file: BuildAsset)
}

/// Represents a generic build asset with its file path and extension
pub type BuildAsset {
  BuildAsset(path: String, extension: String)
}

@internal
pub fn new_build_asset(path: String) {
  BuildAsset(path:, extension: case filepath.extension(path) {
    Ok(ext) -> "." <> ext
    _ -> ""
  })
}

/// Add an additional extension to a build asset's path
///
/// Example: "file.gleam" + ".js" -> "file.gleam.js"
pub fn add_extension(asset: BuildAsset, extension: String) {
  new_build_asset(asset.path <> extension)
}

/// Replace the extension of a build asset
///
/// Example: "file.gleam" changed to ".js" -> "file.js"
pub fn change_extension(asset: BuildAsset, extension: String) {
  new_build_asset(filepath.strip_extension(asset.path) <> extension)
}
