const std = @import("std");
const Io = std.Io;
const Allocator = std.mem.Allocator;

const Mesh = @import("../Mesh.zig");
const Builder = @import("../Builder.zig");
const math = @import("../math.zig");
const Vector3 = math.Vector3(f32);
const le = @import("../utils.zig").le;

pub const Encoding = enum {
    ascii,
    binary,
};

pub const ReadOptions = struct {};

pub const WriteOptions = struct {
    encoding: Encoding = .binary,
    /// Solid name emitted in ascii output.
    name: []const u8 = "mesh",
};

/// Parse an STL from any reader. It automatically detects between ascii and binary
pub fn read(r: *Io.Reader, alloc: Allocator) !Mesh {
    const head = try r.peek(5);
    return if (std.mem.eql(u8, head, "solid"))
        readAscii(r, alloc)
    else
        readBinary(r, alloc);
}

/// Parse an ascii STL from any reader.
pub fn readAscii(r: *Io.Reader, alloc: Allocator) !Mesh {
    // skip header
    _ = try r.takeDelimiter('\n');

    var builder: Builder = .init();
    errdefer builder.deinit(alloc);

    var vertices: [3]Vector3 = undefined;
    var normal: Vector3 = .zero;

    while (true) {
        if (try r.takeDelimiter('\n')) |nl| {
            var split = std.mem.tokenizeAny(u8, nl, " \t\r");
            const h = split.next().?; // facet or endsolid
            if (std.mem.eql(u8, h, "endsolid")) break;
            _ = split.next(); // normal

            normal = .{
                .x = try std.fmt.parseFloat(f32, split.next().?),
                .y = try std.fmt.parseFloat(f32, split.next().?),
                .z = try std.fmt.parseFloat(f32, split.next().?),
            };
        }

        _ = try r.takeDelimiter('\n'); // outer loop

        for (0..3) |i| {
            const nl = (try r.takeDelimiter('\n')) orelse return error.UnexpectedEof;
            var split = std.mem.tokenizeAny(u8, nl, " \t\r");
            _ = split.next(); // vertex

            vertices[i] = .{
                .x = try std.fmt.parseFloat(f32, split.next().?),
                .y = try std.fmt.parseFloat(f32, split.next().?),
                .z = try std.fmt.parseFloat(f32, split.next().?),
            };
        }

        try builder.addTriangle(alloc, vertices[0], vertices[1], vertices[2], normal);

        _ = try r.takeDelimiter('\n'); // endloop
        _ = try r.takeDelimiter('\n'); // endfacet

    }

    return builder.toMesh(alloc);
}

/// Parse a binary STL from any reader.
pub fn readBinary(r: *Io.Reader, alloc: Allocator) !Mesh {
    // skip header
    _ = try r.discard(.limited(80));
    const triangles_count: usize = try r.takeInt(u32, .little);

    var builder: Builder = try .initCapacity(alloc, triangles_count);
    errdefer builder.deinit(alloc);

    var vertices: [3]Vector3 = undefined;

    for (0..triangles_count) |_| {
        const normal = try r.takeStruct(Vector3, .little);
        for (0..3) |i| {
            vertices[i] = try r.takeStruct(Vector3, .little);
        }
        // skip attribute bytes
        _ = try r.discard(.limited(2));
        try builder.addTriangle(alloc, vertices[0], vertices[1], vertices[2], normal);
    }

    return builder.toMesh(alloc);
}

/// Write the mesh as STL to any writer.
pub fn write(mesh: *const Mesh, w: *Io.Writer, options: WriteOptions) !void {
    return switch (options.encoding) {
        .ascii => writeAscii(mesh, w, options),
        .binary => writeBinary(mesh, w),
    };
}

/// Write the mesh as an ascii STL.
pub fn writeAscii(mesh: *const Mesh, w: *Io.Writer, options: WriteOptions) !void {
    try w.print("solid {s}\n", .{options.name});
    for (0..mesh.triangles_count) |t| {
        const n = mesh.normals[t];
        try w.print("  facet normal {d} {d} {d}\n", .{ n.x, n.y, n.z });
        try w.writeAll("    outer loop\n");
        for (mesh.getTriangle(t)) |v| {
            try w.print("      vertex {d} {d} {d}\n", .{ v.x, v.y, v.z });
        }
        try w.writeAll("    endloop\n");
        try w.writeAll("  endfacet\n");
    }
    try w.print("endsolid {s}\n", .{options.name});
}

/// Write the mesh as a binary STL.
pub fn writeBinary(mesh: *const Mesh, w: *Io.Writer) !void {
    try w.writeAll(&[_]u8{0} ** 80); // header
    try w.writeInt(u32, @intCast(mesh.triangles_count), .little);

    for (0..mesh.triangles_count) |t| {
        try w.writeStruct(mesh.normals[t], .little);
        for (mesh.getTriangle(t)) |v| {
            try w.writeStruct(v, .little);
        }
        try w.writeAll(&[_]u8{0} ** 2); // attribute
    }
}

test "read auto-detects an ascii STL" {
    const alloc = std.testing.allocator;
    const stl_ascii =
        \\solid tri
        \\facet normal 0 0 1
        \\  outer loop
        \\    vertex 0 0 0
        \\    vertex 1 0 0
        \\    vertex 0 1 0
        \\  endloop
        \\endfacet
        \\endsolid tri
        \\
    ;
    var r: Io.Reader = .fixed(stl_ascii);
    const mesh = try read(&r, alloc);
    defer mesh.deinit(alloc);
    try std.testing.expectEqual(@as(usize, 1), mesh.triangles_count);
    try std.testing.expectEqual(@as(usize, 3), mesh.vertices.len);
}

test "read auto-detects a binary STL" {
    const alloc = std.testing.allocator;
    const stl_binary =
        [_]u8{0} ** 80 ++ // header does not begin with "solid"
        le.u32Bytes(1) ++
        le.f32Bytes(0) ++ le.f32Bytes(0) ++ le.f32Bytes(1) ++
        le.f32Bytes(0) ++ le.f32Bytes(0) ++ le.f32Bytes(0) ++
        le.f32Bytes(1) ++ le.f32Bytes(0) ++ le.f32Bytes(0) ++
        le.f32Bytes(0) ++ le.f32Bytes(1) ++ le.f32Bytes(0) ++
        [_]u8{ 0, 0 };
    var r: Io.Reader = .fixed(&stl_binary);
    const mesh = try read(&r, alloc);
    defer mesh.deinit(alloc);
    try std.testing.expectEqual(@as(usize, 1), mesh.triangles_count);
    try std.testing.expectEqual(@as(usize, 3), mesh.vertices.len);
}

test "readAscii reads a single triangle" {
    const alloc = std.testing.allocator;
    const stl =
        \\solid tri
        \\facet normal 1 0 0
        \\  outer loop
        \\    vertex 0 0 5
        \\    vertex 1 0 3
        \\    vertex 0 1 2
        \\  endloop
        \\endfacet
        \\endsolid tri
        \\
    ;
    var r: Io.Reader = .fixed(stl);
    const mesh = try readAscii(&r, alloc);
    defer mesh.deinit(alloc);

    try std.testing.expectEqual(@as(usize, 1), mesh.triangles_count);
    try std.testing.expectEqual(@as(usize, 3), mesh.vertices.len);
    try std.testing.expectEqual(@as(usize, 3), mesh.indices.len);
    try std.testing.expectEqual(@as(usize, 1), mesh.normals.len);

    try std.testing.expect(mesh.normals[0].eql(.init(1, 0, 0)));

    const t = mesh.getTriangle(0);
    try std.testing.expect(t[0].eql(.init(0, 0, 5)));
    try std.testing.expect(t[1].eql(.init(1, 0, 3)));
    try std.testing.expect(t[2].eql(.init(0, 1, 2)));
}

test "readAscii deduplicates vertices shared between triangles" {
    const alloc = std.testing.allocator;
    const stl =
        \\solid quad
        \\facet normal 0 0 1
        \\  outer loop
        \\    vertex 0 0 0
        \\    vertex 1 0 0
        \\    vertex 1 1 0
        \\  endloop
        \\endfacet
        \\facet normal 0 0 1
        \\  outer loop
        \\    vertex 0 0 0
        \\    vertex 1 1 0
        \\    vertex 0 1 0
        \\  endloop
        \\endfacet
        \\endsolid quad
        \\
    ;
    var r: Io.Reader = .fixed(stl);
    const mesh = try readAscii(&r, alloc);
    defer mesh.deinit(alloc);

    try std.testing.expectEqual(@as(usize, 2), mesh.triangles_count);
    try std.testing.expectEqual(@as(usize, 4), mesh.vertices.len);
    try std.testing.expectEqualSlices(usize, &.{ 0, 1, 2, 0, 2, 3 }, mesh.indices);
}

test "readAscii tolerates CRLF line endings" {
    const alloc = std.testing.allocator;
    const stl =
        "solid tri\r\n" ++
        "facet normal 0 0 1\r\n" ++
        "  outer loop\r\n" ++
        "    vertex 0 0 0\r\n" ++
        "    vertex 1 0 0\r\n" ++
        "    vertex 0 1 0\r\n" ++
        "  endloop\r\n" ++
        "endfacet\r\n" ++
        "endsolid tri\r\n";
    var r: Io.Reader = .fixed(stl);
    const mesh = try readAscii(&r, alloc);
    defer mesh.deinit(alloc);

    try std.testing.expectEqual(@as(usize, 1), mesh.triangles_count);
    try std.testing.expect(mesh.normals[0].eql(.init(0, 0, 1)));
    try std.testing.expect(mesh.getTriangle(0)[1].eql(.init(1, 0, 0)));
}

test "readAscii returns error on a truncated triangle" {
    const alloc = std.testing.allocator;
    const stl =
        \\solid tri
        \\facet normal 0 0 1
        \\  outer loop
        \\    vertex 0 0 0
    ;
    var r: Io.Reader = .fixed(stl);
    try std.testing.expectError(error.UnexpectedEof, readAscii(&r, alloc));
}

test "readBinary reads a single triangle" {
    const alloc = std.testing.allocator;
    const stl =
        [_]u8{0} ** 80 ++ // header
        le.u32Bytes(1) ++ // triangle count
        le.f32Bytes(0) ++ le.f32Bytes(0) ++ le.f32Bytes(1) ++ // normal
        le.f32Bytes(0) ++ le.f32Bytes(0) ++ le.f32Bytes(0) ++ // v0
        le.f32Bytes(1) ++ le.f32Bytes(0) ++ le.f32Bytes(0) ++ // v1
        le.f32Bytes(0) ++ le.f32Bytes(1) ++ le.f32Bytes(0) ++ // v2
        [_]u8{ 0, 0 }; // attribute byte count
    var r: Io.Reader = .fixed(&stl);
    const mesh = try readBinary(&r, alloc);
    defer mesh.deinit(alloc);

    try std.testing.expectEqual(@as(usize, 1), mesh.triangles_count);
    try std.testing.expectEqual(@as(usize, 3), mesh.vertices.len);
    try std.testing.expectEqual(@as(usize, 1), mesh.normals.len);

    try std.testing.expect(mesh.normals[0].eql(.init(0, 0, 1)));
    const t = mesh.getTriangle(0);
    try std.testing.expect(t[0].eql(.init(0, 0, 0)));
    try std.testing.expect(t[1].eql(.init(1, 0, 0)));
    try std.testing.expect(t[2].eql(.init(0, 1, 0)));
}

test "readBinary deduplicates vertices shared between triangles" {
    const alloc = std.testing.allocator;
    const stl =
        [_]u8{0} ** 80 ++
        le.u32Bytes(2) ++
        // triangle 1
        le.f32Bytes(0) ++ le.f32Bytes(0) ++ le.f32Bytes(1) ++ // normal
        le.f32Bytes(0) ++ le.f32Bytes(0) ++ le.f32Bytes(0) ++ // v0
        le.f32Bytes(1) ++ le.f32Bytes(0) ++ le.f32Bytes(0) ++ // v1
        le.f32Bytes(1) ++ le.f32Bytes(1) ++ le.f32Bytes(0) ++ // v2
        [_]u8{ 0, 0 } ++
        // triangle 2
        le.f32Bytes(0) ++ le.f32Bytes(0) ++ le.f32Bytes(1) ++ // normal
        le.f32Bytes(0) ++ le.f32Bytes(0) ++ le.f32Bytes(0) ++ // v0
        le.f32Bytes(1) ++ le.f32Bytes(1) ++ le.f32Bytes(0) ++ // v1
        le.f32Bytes(0) ++ le.f32Bytes(1) ++ le.f32Bytes(0) ++ // v2
        [_]u8{ 0, 0 };
    var r: Io.Reader = .fixed(&stl);
    const mesh = try readBinary(&r, alloc);
    defer mesh.deinit(alloc);

    try std.testing.expectEqual(@as(usize, 2), mesh.triangles_count);
    try std.testing.expectEqual(@as(usize, 4), mesh.vertices.len);
    try std.testing.expectEqualSlices(usize, &.{ 0, 1, 2, 0, 2, 3 }, mesh.indices);
}

test "writeAscii emits a well-formed ascii STL" {
    var vertices = [_]Vector3{ .init(0, 0, 0), .init(1, 0, 0), .init(0, 1, 0) };
    var indices = [_]usize{ 0, 1, 2 };
    var normals = [_]Vector3{.init(0, 0, 1)};
    const mesh: Mesh = .{
        .vertices = &vertices,
        .indices = &indices,
        .normals = &normals,
        .triangles_count = 1,
    };

    var buf: [512]u8 = undefined;
    var w: Io.Writer = .fixed(&buf);
    try writeAscii(&mesh, &w, .{});

    const expected =
        \\solid mesh
        \\  facet normal 0 0 1
        \\    outer loop
        \\      vertex 0 0 0
        \\      vertex 1 0 0
        \\      vertex 0 1 0
        \\    endloop
        \\  endfacet
        \\endsolid mesh
        \\
    ;
    try std.testing.expectEqualStrings(expected, w.buffered());
}

test "writeAscii emits the configured solid name" {
    var vertices = [_]Vector3{ .init(0, 0, 0), .init(1, 0, 0), .init(0, 1, 0) };
    var indices = [_]usize{ 0, 1, 2 };
    var normals = [_]Vector3{.init(0, 0, 1)};
    const mesh: Mesh = .{
        .vertices = &vertices,
        .indices = &indices,
        .normals = &normals,
        .triangles_count = 1,
    };

    var buf: [512]u8 = undefined;
    var w: Io.Writer = .fixed(&buf);
    try writeAscii(&mesh, &w, .{ .name = "part" });

    try std.testing.expect(std.mem.startsWith(u8, w.buffered(), "solid part\n"));
    try std.testing.expect(std.mem.endsWith(u8, w.buffered(), "endsolid part\n"));
}

test "writeAscii preserves fractional and negative coordinates" {
    const alloc = std.testing.allocator;
    var vertices = [_]Vector3{ .init(-0.5, 0.25, 1.5), .init(2.5, -1.25, 0), .init(0, 3.75, -2) };
    var indices = [_]usize{ 0, 1, 2 };
    var normals = [_]Vector3{.init(0, 0, -1)};
    const mesh: Mesh = .{
        .vertices = &vertices,
        .indices = &indices,
        .normals = &normals,
        .triangles_count = 1,
    };

    var buf: [512]u8 = undefined;
    var w: Io.Writer = .fixed(&buf);
    try writeAscii(&mesh, &w, .{});

    var r: Io.Reader = .fixed(w.buffered());
    const parsed = try readAscii(&r, alloc);
    defer parsed.deinit(alloc);

    try std.testing.expect(parsed.normals[0].eql(.init(0, 0, -1)));
    const t = parsed.getTriangle(0);
    try std.testing.expect(t[0].eql(.init(-0.5, 0.25, 1.5)));
    try std.testing.expect(t[1].eql(.init(2.5, -1.25, 0)));
    try std.testing.expect(t[2].eql(.init(0, 3.75, -2)));
}

test "writeBinary emits the exact STL byte layout" {
    var vertices = [_]Vector3{ .init(0, 0, 0), .init(1, 0, 0), .init(0, 1, 0) };
    var indices = [_]usize{ 0, 1, 2 };
    var normals = [_]Vector3{.init(0, 0, 1)};
    const mesh: Mesh = .{
        .vertices = &vertices,
        .indices = &indices,
        .normals = &normals,
        .triangles_count = 1,
    };

    var buf: [256]u8 = undefined;
    var w: Io.Writer = .fixed(&buf);
    try writeBinary(&mesh, &w);

    const expected =
        [_]u8{0} ** 80 ++ // header
        le.u32Bytes(1) ++ // triangle count
        le.f32Bytes(0) ++ le.f32Bytes(0) ++ le.f32Bytes(1) ++ // normal
        le.f32Bytes(0) ++ le.f32Bytes(0) ++ le.f32Bytes(0) ++ // v0
        le.f32Bytes(1) ++ le.f32Bytes(0) ++ le.f32Bytes(0) ++ // v1
        le.f32Bytes(0) ++ le.f32Bytes(1) ++ le.f32Bytes(0) ++ // v2
        [_]u8{ 0, 0 }; // attribute byte count
    try std.testing.expectEqualSlices(u8, &expected, w.buffered());
}

test "write ascii output round-trips through read" {
    const primitives = @import("../primitives.zig");
    const alloc = std.testing.allocator;
    const cube = try primitives.cube(alloc, 2);
    defer cube.deinit(alloc);

    var buf: [8192]u8 = undefined;
    var w: Io.Writer = .fixed(&buf);
    try write(&cube, &w, .{ .encoding = .ascii });

    var r: Io.Reader = .fixed(w.buffered());
    const parsed = try read(&r, alloc);
    defer parsed.deinit(alloc);

    try expectMeshesEqual(cube, parsed);
}

test "write binary output round-trips through read" {
    const primitives = @import("../primitives.zig");
    const alloc = std.testing.allocator;
    const cube = try primitives.cube(alloc, 2);
    defer cube.deinit(alloc);

    var buf: [1024]u8 = undefined;
    var w: Io.Writer = .fixed(&buf);
    try write(&cube, &w, .{ .encoding = .binary });

    try std.testing.expectEqual(84 + 50 * cube.triangles_count, w.buffered().len);

    var r: Io.Reader = .fixed(w.buffered());
    const parsed = try read(&r, alloc);
    defer parsed.deinit(alloc);

    try expectMeshesEqual(cube, parsed);
}

fn expectMeshesEqual(expected: Mesh, actual: Mesh) !void {
    try std.testing.expectEqual(expected.triangles_count, actual.triangles_count);
    try std.testing.expectEqualSlices(usize, expected.indices, actual.indices);
    for (expected.vertices, actual.vertices) |e, a| try std.testing.expect(e.eql(a));
    for (expected.normals, actual.normals) |e, a| try std.testing.expect(e.eql(a));
}
