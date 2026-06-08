const std = @import("std");
const math = @import("math.zig");
const BoundingBox = @import("BoundingBox.zig");
const Vector3 = math.Vector3;
const Allocator = std.mem.Allocator;
const Io = std.Io;
const ArrayList = std.ArrayList;

pub const Mesh = @This();

vertices: []Vector3,
indices: []usize,
normals: []Vector3,
triangles_count: usize,

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

    const triangles_count = 1000;
    var vertices: ArrayList(Vector3) = try .initCapacity(alloc, triangles_count * 3);
    errdefer vertices.deinit(alloc);
    var normals: ArrayList(Vector3) = try .initCapacity(alloc, triangles_count);
    errdefer normals.deinit(alloc);
    var indices: ArrayList(usize) = try .initCapacity(alloc, triangles_count * 3);
    errdefer indices.deinit(alloc);

    var hm: std.AutoHashMap([12]u8, usize) = .init(alloc);
    defer hm.deinit();

    while (true) {
        if (try r.takeDelimiter('\n')) |nl| {
            var split = std.mem.tokenizeAny(u8, nl, " \t\r");
            const h = split.next().?; // facet or endsolid
            if (std.mem.eql(u8, h, "endsolid")) break;
            _ = split.next(); // normal

            const normal: Vector3 = .{ .x = try std.fmt.parseFloat(f32, split.next().?), .y = try std.fmt.parseFloat(f32, split.next().?), .z = try std.fmt.parseFloat(f32, split.next().?) };
            try normals.append(alloc, normal);
        }

        _ = try r.takeDelimiter('\n'); // outer loop

        for (0..3) |_| {
            const nl = (try r.takeDelimiter('\n')) orelse return error.UnexpectedEof;
            var split = std.mem.tokenizeAny(u8, nl, " \t\r");
            _ = split.next(); // vertex

            const vertex: Vector3 = .{
                .x = try std.fmt.parseFloat(f32, split.next().?),
                .y = try std.fmt.parseFloat(f32, split.next().?),
                .z = try std.fmt.parseFloat(f32, split.next().?),
            };

            const key: [12]u8 = @bitCast(vertex);
            const gop = try hm.getOrPut(key);
            if (!gop.found_existing) {
                gop.value_ptr.* = vertices.items.len;
                try vertices.append(alloc, vertex);
            }
            try indices.append(alloc, gop.value_ptr.*);
        }

        _ = try r.takeDelimiter('\n'); // endloop
        _ = try r.takeDelimiter('\n'); // endfacet

    }

    const verts = try vertices.toOwnedSlice(alloc);
    errdefer alloc.free(verts);
    const inds = try indices.toOwnedSlice(alloc);
    errdefer alloc.free(inds);
    const norms = try normals.toOwnedSlice(alloc);

    return .{ .vertices = verts, .indices = inds, .normals = norms, .triangles_count = norms.len };
}

/// Parse a binary STL from any reader.
pub fn parseBinary(r: *Io.Reader, alloc: Allocator) !Mesh {
    // skip header
    _ = try r.discard(.limited(80));
    const triangles_count: usize = try r.takeInt(u32, .little);

    var vertices: ArrayList(Vector3) = try .initCapacity(alloc, triangles_count * 3);
    errdefer vertices.deinit(alloc);
    var normals: ArrayList(Vector3) = try .initCapacity(alloc, triangles_count);
    errdefer normals.deinit(alloc);
    var indices: ArrayList(usize) = try .initCapacity(alloc, triangles_count * 3);
    errdefer indices.deinit(alloc);

    var hm: std.AutoHashMap([12]u8, usize) = .init(alloc);
    defer hm.deinit();
    try hm.ensureTotalCapacity(@intCast(triangles_count * 3));

    for (0..triangles_count) |_| {
        const nb: [12]u8 = (try r.takeArray(12)).*;
        const normal: Vector3 = @bitCast(nb);
        for (0..3) |_| {
            const vb: [12]u8 = (try r.takeArray(12)).*;
            const gop = hm.getOrPutAssumeCapacity(vb);
            if (!gop.found_existing) {
                gop.value_ptr.* = vertices.items.len;
                vertices.appendAssumeCapacity(@bitCast(vb));
            }
            indices.appendAssumeCapacity(gop.value_ptr.*);
        }
        // skip attribute bytes
        _ = try r.discard(.limited(2));
        normals.appendAssumeCapacity(normal);
    }

    const verts = try vertices.toOwnedSlice(alloc);
    errdefer alloc.free(verts);
    const inds = try indices.toOwnedSlice(alloc);
    errdefer alloc.free(inds);
    const norms = try normals.toOwnedSlice(alloc);

    return .{ .vertices = verts, .indices = inds, .normals = norms, .triangles_count = triangles_count };
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
    var max: Vector3 = .splat(std.math.floatMin(f32));
    for (self.vertices) |v| {
        max = max.max(v);
        min = min.min(v);
    }
    return .{ .min = min, .max = max };
}
