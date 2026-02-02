import builder/context.{type BuildContext}
import builder/module.{type Module}
import filepath
import glance
import gleam/dict
import gleam/list
import gleam/option.{type Option, None, Some}

/// Represents a resolved type definition with its source module
pub type TypeDefinition {
  TypeAlias(source: glance.Definition(glance.TypeAlias), module: Module)
  CustomType(source: glance.Definition(glance.CustomType), module: Module)
}

/// Searches for the type definition in the current module and follows imports
/// to resolve qualified and unqualified type references.
pub fn find_type_definition(
  ctx: BuildContext,
  type_: glance.Type,
  module: Module,
) -> Result(TypeDefinition, Nil) {
  find_type_definition_do(ctx, type_, module, True)
}

fn find_type_definition_do(
  ctx: BuildContext,
  type_: glance.Type,
  module: Module,
  inspect_imports: Bool,
) -> Result(TypeDefinition, Nil) {
  case type_ {
    glance.NamedType(name:, module: module_name, ..) ->
      case module_name {
        Some(_) ->
          case inspect_imports {
            True ->
              find_type_definition_in_import(ctx, name, module_name, module)
            _ -> Error(Nil)
          }
        _ -> {
          let custom_type =
            module.custom_types
            |> list.find(fn(x) { x.definition.name == name })

          let type_alias =
            module.type_aliases
            |> list.find(fn(x) { x.definition.name == name })

          case custom_type, type_alias {
            Ok(custom_type), _ -> Ok(CustomType(source: custom_type, module:))
            _, Ok(type_alias) -> Ok(TypeAlias(source: type_alias, module:))
            _, _ ->
              case inspect_imports {
                True -> find_type_definition_in_import(ctx, name, None, module)
                _ -> Error(Nil)
              }
          }
        }
      }
    glance.TupleType(..) -> Error(Nil)
    _ -> panic
  }
}

fn find_type_definition_in_import(
  ctx: BuildContext,
  type_name: String,
  type_module_name: Option(String),
  module: Module,
) -> Result(TypeDefinition, Nil) {
  let import_ =
    module.imports
    |> list.find_map(fn(x) {
      case type_module_name {
        Some(name) -> {
          let module_name = case x.definition.alias {
            Some(module_name) ->
              case module_name {
                glance.Named(name) -> name
                glance.Discarded(name) -> name
              }
            _ -> {
              filepath.base_name(x.definition.module)
            }
          }
          case module_name == name {
            True -> Ok(#(x.definition.module, type_name))
            _ -> Error(Nil)
          }
        }
        None -> {
          case
            x.definition.unqualified_types
            |> list.find(fn(x) {
              case x.alias {
                Some(name) -> name == type_name
                _ -> x.name == type_name
              }
            })
          {
            Ok(unqualified_type) ->
              Ok(#(x.definition.module, unqualified_type.name))
            _ -> Error(Nil)
          }
        }
      }
    })

  case import_ {
    Ok(import_) -> {
      case dict.get(context.modules(ctx), import_.0) {
        Ok(module) ->
          find_type_definition_do(
            ctx,
            glance.NamedType(
              location: glance.Span(0, 0),
              name: import_.1,
              module: None,
              parameters: [],
            ),
            module,
            False,
          )
        Error(_) -> Error(Nil)
      }
    }
    Error(_) -> Error(Nil)
  }
}

/// Check if a type is a Gleam prelude type (built-in type)
///
/// Returns True for types like Int, Float, Bool, String, Nil, BitArray, List,
/// Result, tuples, and functions that don't have custom definitions.
pub fn is_prelude_type(
  ctx: BuildContext,
  type_: glance.Type,
  current_module: Module,
) -> Bool {
  case find_type_definition(ctx, type_, current_module) {
    Ok(_) -> False
    _ -> {
      let check = fn(name) {
        case name {
          "Bool"
          | "Int"
          | "Float"
          | "String"
          | "Nil"
          | "BitArray"
          | "List"
          | "Result" -> True
          _ -> False
        }
      }

      case type_ {
        glance.TupleType(..) -> True
        glance.FunctionType(..) -> True
        glance.NamedType(name:, module:, ..) ->
          case module {
            Some(_) -> False
            _ -> check(name)
          }
        glance.VariableType(name:, ..) -> check(name)
        glance.HoleType(name:, ..) -> check(name)
      }
    }
  }
}

/// Find a specific attribute by name in a definition
///
/// Returns the attribute along with the definition it belongs to.
pub fn find_attribute(
  definition: glance.Definition(definition),
  attribute_name: String,
) -> Result(#(glance.Attribute, definition), Nil) {
  list.find_map(definition.attributes, fn(attribute) {
    case attribute.name == attribute_name {
      True -> Ok(#(attribute, definition.definition))
      False -> Error(Nil)
    }
  })
}

/// Filter a list of definitions to only those with a specific attribute
///
/// Returns pairs of the matching attribute and its definition.
pub fn filter_attributes(
  definitions: List(glance.Definition(definition)),
  attribute_name: String,
) -> List(#(glance.Attribute, definition)) {
  list.filter_map(definitions, find_attribute(_, attribute_name))
}
