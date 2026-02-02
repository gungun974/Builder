# Gleam Codegen

A monorepo for Gleam code generation tools.

## Projects

### Builder 🔨

Builder is a **code generation framework** for Gleam that enables easy and universal code generation.
It provides the infrastructure to create custom code generators (called "builders") with built-in support for file watching, project analysis, and build lifecycle management.

[→ Read Builder README](./builder/README.md)

### Sara 🦑

Sara is a **serialization code generator** for Gleam. It generates type-safe JSON encoding and decoding functions for your Gleam custom types at build time using simple annotations like `//@json_encode()` and `//@json_decode()`.

[→ Read Sara README](./sara/README.md)

See the `example` directory to have a concrete example
