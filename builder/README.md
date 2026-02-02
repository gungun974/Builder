# Builder 🔨

Builder is a **code generation framework** for Gleam that enables easy and universal code generation.

## What is a Builder?

Builder provides the infrastructure to create custom code generators (called "builders") for Gleam projects. It handles file watching, project analysis, and the build lifecycle, letting you focus on the generation logic.

## Creating a Builder

### 1. Basic Builder Structure

A builder is created using one of these constructor functions:

**Single File Builder** - Processes each matching file individually:
```gleam
builder.new_gleam_builder(fn(ctx, gleam_asset) {
  Nil
})

builder.new_generic_builder(["txt", "md"], fn(ctx, asset) {
  Nil
})
```

**Multiple Files Builder** - Processes all files together in one batch:
```gleam
builder.new_gleam_multiple_builder(fn(ctx, gleam_assets) {
  Nil
})

builder.new_generic_multiple_builder(["css"], fn(ctx, assets) {
  Nil
})
```

### 2. Working with Gleam Modules

For Gleam builders, the `input` parameter provides access to the parsed module:

```gleam
import builder/inspect

pub fn my_builder() {
  builder.new_gleam_builder(fn(ctx, input) {
    let annotated_types =
      input.module.custom_types
      |> inspect.filter_attributes("my_annotation")

    Nil
  })
}
```

### 3. Generating Code

The `BuildContext` help you read and write new files.
It's abstract the file system which make more simple after to write tests to check behavior.

***Please note you can't write file your builder have read access*** 

```gleam
import builder/context
import builder/asset
import builder/format

pub fn my_builder() {
  builder.new_gleam_builder(fn(ctx, input) {
    let generated_code = "pub fn hello() { \"Hello!\" }"

    let assert Ok(formatted) = format.format_gleam_code(generated_code)

    let _ = context.write(
      ctx,
      input.file |> asset.change_extension("_generated.gleam"),
      formatted,
    )

    Nil
  })
}
```

### 4. Running Your Builder

Create a new gleam project inside your existing project `gleam new build_runner`

```bash
gleam new build_runner
cd build_runner
```

Install `builder` modules. (Not dev dependencies)

Edit `src/build_runner.gleam`:

```gleam
import builder
import my_package/my_builder

pub fn main() {
  builder.execute_builders([
    my_builder.my_builder(),
  ])
}
```

Make your main project depend on the build runner:

```toml
[dev-dependencies]
build_runner = { path = "./build_runner" }
```

Run the builder:

```bash
gleam run -m build_runner
```

Or use watch mode for continuous regeneration:

```bash
gleam run -m build_runner watch
```
