# three.zig

[![CI](https://github.com/Sheol27/three.zig/actions/workflows/ci.yml/badge.svg)](https://github.com/Sheol27/three.zig/actions/workflows/ci.yml)
[![Zig](https://img.shields.io/badge/Zig-0.16.0-f7a41d?logo=zig&logoColor=white)](https://ziglang.org/)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

A Zig library for loading and processing meshes.

Requires Zig `0.16.0`.

## Roadmap

> Under active development, APIs may change.

- More loaders: OBJ, PLY, glTF...
- Writers for supported formats
- Mesh processing: normals, transforms, simplification, validation
- Compile to C compatible library
- Compile to Wasm with JS glue

## Install

Fetch and save the dependency:

```sh
zig fetch --save git+https://github.com/Sheol27/three.zig
```

Wire it into your `build.zig`:

```zig
const three = b.dependency("three", .{
    .target = target,
    .optimize = optimize,
});

exe.root_module.addImport("three", three.module("three"));
```

## Usage

```zig
const std = @import("std");
const three = @import("three");

pub fn main(init: std.process.Init) !void {
    const allocator = init.arena.allocator();

    const mesh: three.Mesh = try .fromFile(init.io, allocator, "model.stl");
    defer mesh.deinit(allocator);

    std.debug.print("triangles: {}\n", .{mesh.triangles_count});

    const bb = mesh.computeBoundingBox();
    std.debug.print("center: {any}\n", .{bb.center()});
}
```

You can also parse from any `std.Io.Reader` via `Mesh.fromReader`, or
explicitly call `Mesh.parseAscii` / `Mesh.parseBinary`.

## Example

Run the bundled example against an STL file:

```sh
zig build run -- path/to/model.stl
```

## Test

```sh
zig build test
```

## Contributing

Contributions are welcome, open an issue or PR!

## License

[MIT](LICENSE)
