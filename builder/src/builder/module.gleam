import glance.{
  type Constant, type CustomType, type Definition, type Function, type Import,
  type TypeAlias,
}

/// Represents a parsed Gleam module with all its definitions
///
/// Contains the module's metadata (name, package, path) along with all its
/// top-level definitions including imports, types, constants, and functions.
pub type Module {
  Module(
    name: String,
    package: String,
    path: String,
    imports: List(Definition(Import)),
    custom_types: List(Definition(CustomType)),
    type_aliases: List(Definition(TypeAlias)),
    constants: List(Definition(Constant)),
    functions: List(Definition(Function)),
    external: Bool,
    file: String,
  )
}
