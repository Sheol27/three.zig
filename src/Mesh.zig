const std = @import("std");
const math = @import("math.zig");
const BoundingBox = @import("BoundingBox.zig");
const Vector3 = math.Vector3;
const Allocator = std.mem.Allocator;
const Io = std.Io;
const ArrayList = std.ArrayList;
const Builder = @import("Builder.zig");

pub const Mesh = @This();

vertices: []Vector3,
indices: []usize,
normals: []Vector3,
triangles_count: usize,

pub fn getTriangle(self: *const Mesh, index: usize) [3]Vector3 {
    return .{ self.vertices[self.indices[index]], self.vertices[self.indices[index + 1]], self.vertices[self.indices[index + 2]] };
}

/// Parse an STL from any reader. It automatically detects beteen ascii and binary
pub fn fromReader(r: *Io.Reader, alloc: Allocator) !Mesh {
    const head = try r.peek(5);
    return if (std.mem.eql(u8, head, "solid"))
        parseAscii(r, alloc)
    else
        parseBinary(r, alloc);
}

// Parse an ascii STL from any reader.
pub fn parseAscii(r: *Io.Reader, alloc: Allocator) !Mesh {
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
pub fn parseBinary(r: *Io.Reader, alloc: Allocator) !Mesh {
    // skip header
    _ = try r.discard(.limited(80));
    const triangles_count: usize = try r.takeInt(u32, .little);

    var builder: Builder = try .initCapacity(alloc, triangles_count);
    errdefer builder.deinit(alloc);

    var vertices: [3]Vector3 = undefined;

    for (0..triangles_count) |_| {
        const nb: [12]u8 = (try r.takeArray(12)).*;
        const normal: Vector3 = @bitCast(nb);
        for (0..3) |i| {
            const vb: [12]u8 = (try r.takeArray(12)).*;
            vertices[i] = @bitCast(vb);
        }
        // skip attribute bytes
        _ = try r.discard(.limited(2));
        try builder.addTriangle(alloc, vertices[0], vertices[1], vertices[2], normal);
    }

    return builder.toMesh(alloc);
}

/// Open a file by path and parse it.
pub fn fromFile(io: Io, alloc: Allocator, path: []const u8) !Mesh {
    const dir = Io.Dir.cwd();
    var file = try dir.openFile(io, path, .{});
    defer file.close(io);
    var buffer: [1024 * 128]u8 = undefined;
    var reader = file.reader(io, &buffer);
    return fromReader(&reader.interface, alloc);
}

pub fn deinit(self: *const Mesh, alloc: Allocator) void {
    alloc.free(self.vertices);
    alloc.free(self.indices);
    alloc.free(self.normals);
}

pub fn computeBoundingBox(self: *const Mesh) BoundingBox {
    var min: Vector3 = .splat(std.math.floatMax(f32));
    var max: Vector3 = .splat(-std.math.floatMax(f32));
    for (self.vertices) |v| {
        max = max.max(v);
        min = min.min(v);
    }
    return .{ .min = min, .max = max };
}

test "computeBoundingBox spans every vertex" {
    var vertices = [_]Vector3{
        .init(0, 0, 0),
        .init(1, 2, 3),
        .init(-1, 5, 2),
    };
    const mesh: Mesh = .{
        .vertices = &vertices,
        .indices = &[_]usize{},
        .normals = &[_]Vector3{},
        .triangles_count = 0,
    };
    const bb = mesh.computeBoundingBox();
    try std.testing.expect(bb.min.eql(.init(-1, 0, 0)));
    try std.testing.expect(bb.max.eql(.init(1, 5, 3)));
}

test "computeBoundingBox handles meshes entirely in negative space" {
    var vertices = [_]Vector3{
        .init(-3, -3, -3),
        .init(-1, -2, -5),
    };
    const mesh: Mesh = .{
        .vertices = &vertices,
        .indices = &[_]usize{},
        .normals = &[_]Vector3{},
        .triangles_count = 0,
    };
    const bb = mesh.computeBoundingBox();
    try std.testing.expect(bb.min.eql(.init(-3, -3, -5)));
    try std.testing.expect(bb.max.eql(.init(-1, -2, -3)));
}

test "computeBoundingBox of a single vertex is degenerate" {
    var vertices = [_]Vector3{.init(2, -4, 6)};
    const mesh: Mesh = .{
        .vertices = &vertices,
        .indices = &[_]usize{},
        .normals = &[_]Vector3{},
        .triangles_count = 0,
    };
    const bb = mesh.computeBoundingBox();
    try std.testing.expect(bb.min.eql(.init(2, -4, 6)));
    try std.testing.expect(bb.max.eql(.init(2, -4, 6)));
}

test "parseAscii reads a single triangle" {
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
    const mesh = try parseAscii(&r, alloc);
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

test "parseAscii deduplicates vertices shared between triangles" {
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
    const mesh = try parseAscii(&r, alloc);
    defer mesh.deinit(alloc);

    try std.testing.expectEqual(@as(usize, 2), mesh.triangles_count);
    try std.testing.expectEqual(@as(usize, 4), mesh.vertices.len);
    try std.testing.expectEqualSlices(usize, &.{ 0, 1, 2, 0, 2, 3 }, mesh.indices);
}

test "parseAscii tolerates CRLF line endings" {
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
    const mesh = try parseAscii(&r, alloc);
    defer mesh.deinit(alloc);

    try std.testing.expectEqual(@as(usize, 1), mesh.triangles_count);
    try std.testing.expect(mesh.normals[0].eql(.init(0, 0, 1)));
    try std.testing.expect(mesh.getTriangle(0)[1].eql(.init(1, 0, 0)));
}

test "parseAscii returns error on a truncated triangle" {
    const alloc = std.testing.allocator;
    const stl =
        \\solid tri
        \\facet normal 0 0 1
        \\  outer loop
        \\    vertex 0 0 0
    ;
    var r: Io.Reader = .fixed(stl);
    try std.testing.expectError(error.UnexpectedEof, parseAscii(&r, alloc));
}

test "parseBinary reads a single triangle" {
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
    const mesh = try parseBinary(&r, alloc);
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

test "parseBinary deduplicates vertices shared between triangles" {
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
    const mesh = try parseBinary(&r, alloc);
    defer mesh.deinit(alloc);

    try std.testing.expectEqual(@as(usize, 2), mesh.triangles_count);
    try std.testing.expectEqual(@as(usize, 4), mesh.vertices.len);
    try std.testing.expectEqualSlices(usize, &.{ 0, 1, 2, 0, 2, 3 }, mesh.indices);
}

test "fromReader auto-detects an ascii STL" {
    const alloc = std.testing.allocator;
    const stl =
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
    var r: Io.Reader = .fixed(stl);
    const mesh = try fromReader(&r, alloc);
    defer mesh.deinit(alloc);
    try std.testing.expectEqual(@as(usize, 1), mesh.triangles_count);
    try std.testing.expectEqual(@as(usize, 3), mesh.vertices.len);
}

test "fromReader auto-detects a binary STL" {
    const alloc = std.testing.allocator;
    const stl =
        [_]u8{0} ** 80 ++ // header does not begin with "solid"
        le.u32Bytes(1) ++
        le.f32Bytes(0) ++ le.f32Bytes(0) ++ le.f32Bytes(1) ++
        le.f32Bytes(0) ++ le.f32Bytes(0) ++ le.f32Bytes(0) ++
        le.f32Bytes(1) ++ le.f32Bytes(0) ++ le.f32Bytes(0) ++
        le.f32Bytes(0) ++ le.f32Bytes(1) ++ le.f32Bytes(0) ++
        [_]u8{ 0, 0 };
    var r: Io.Reader = .fixed(&stl);
    const mesh = try fromReader(&r, alloc);
    defer mesh.deinit(alloc);
    try std.testing.expectEqual(@as(usize, 1), mesh.triangles_count);
    try std.testing.expectEqual(@as(usize, 3), mesh.vertices.len);
}

const le = struct {
    fn f32Bytes(v: f32) [4]u8 {
        var b: [4]u8 = undefined;
        std.mem.writeInt(u32, &b, @bitCast(v), .little);
        return b;
    }
    fn u32Bytes(v: u32) [4]u8 {
        var b: [4]u8 = undefined;
        std.mem.writeInt(u32, &b, v, .little);
        return b;
    }
};
