import builder/asset.{type BuildAsset}
import builder/module.{type Module}
import gleam/bool
import gleam/dict.{type Dict}
import gleam/result
import simplifile

/// Error types that can occur during build operations
pub type Error {
  FileError(error: simplifile.FileError)
}

/// Build context containing project modules and file I/O operations
///
/// The context provides access to analyzed modules and functions for reading
/// and writing files during the build process. File operations are optimized
/// to skip writes when content hasn't changed.
pub opaque type BuildContext {
  BuildContext(
    modules: Dict(String, Module),
    read: fn(BuildContext, BuildAsset) -> Result(String, Error),
    read_bits: fn(BuildContext, BuildAsset) -> Result(BitArray, Error),
    write: fn(BuildContext, BuildAsset, String) -> Result(Nil, Error),
    write_bits: fn(BuildContext, BuildAsset, BitArray) -> Result(Nil, Error),
  )
}

@internal
pub fn new_build_context(modules: Dict(String, Module)) -> BuildContext {
  BuildContext(
    modules:,
    read: read_impl,
    read_bits: read_bits_impl,
    write: write_impl,
    write_bits: write_bits_impl,
  )
}

@internal
pub fn new_dummy_build_context(
  modules: Dict(String, Module),
  read: fn(BuildContext, BuildAsset) -> Result(String, Error),
  read_bits: fn(BuildContext, BuildAsset) -> Result(BitArray, Error),
  write: fn(BuildContext, BuildAsset, String) -> Result(Nil, Error),
  write_bits: fn(BuildContext, BuildAsset, BitArray) -> Result(Nil, Error),
) -> BuildContext {
  BuildContext(modules:, read:, read_bits:, write:, write_bits:)
}

fn read_impl(_ctx: BuildContext, asset: BuildAsset) -> Result(String, Error) {
  simplifile.read(asset.path)
  |> result.map_error(fn(err) { FileError(err) })
}

fn read_bits_impl(
  _ctx: BuildContext,
  asset: BuildAsset,
) -> Result(BitArray, Error) {
  simplifile.read_bits(asset.path)
  |> result.map_error(fn(err) { FileError(err) })
}

fn write_impl(
  ctx: BuildContext,
  asset: BuildAsset,
  contents: String,
) -> Result(Nil, Error) {
  use <- bool.guard(read_impl(ctx, asset) == Ok(contents), Ok(Nil))
  simplifile.write(asset.path, contents:)
  |> result.map_error(fn(err) { FileError(err) })
}

fn write_bits_impl(
  ctx: BuildContext,
  asset: BuildAsset,
  bits: BitArray,
) -> Result(Nil, Error) {
  use <- bool.guard(read_bits_impl(ctx, asset) == Ok(bits), Ok(Nil))
  simplifile.write_bits(asset.path, bits:)
  |> result.map_error(fn(err) { FileError(err) })
}

/// Get the dictionary of all analyzed modules in the project
pub fn modules(ctx: BuildContext) {
  ctx.modules
}

/// Read a file's contents as a String
pub fn read(ctx: BuildContext, asset: BuildAsset) {
  ctx.read(ctx, asset)
}

/// Read a file's contents as a BitArray
pub fn read_bits(ctx: BuildContext, asset: BuildAsset) {
  ctx.read_bits(ctx, asset)
}

/// Write a String to a file
///
/// Automatically skips the write if the file already contains the exact same content.
pub fn write(ctx: BuildContext, asset: BuildAsset, contents: String) {
  ctx.write(ctx, asset, contents)
}

/// Write a BitArray to a file
///
/// Automatically skips the write if the file already contains the exact same content.
pub fn write_bits(ctx: BuildContext, asset: BuildAsset, bits: BitArray) {
  ctx.write_bits(ctx, asset, bits)
}
