const Builder = @This();

const std = @import("std");
const math = @import("math.zig");
const Vector3 = math.Vector3;
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const AutoHashMapUnmanaged = std.AutoHashMapUnmanaged;
const Mesh = @import("Mesh.zig");
const triangleNormal = @import("utils.zig").triangleNormal;

vertices: ArrayList(Vector3),
indices: ArrayList(usize),
normals: ArrayList(Vector3),
hm: AutoHashMapUnmanaged([12]u8, usize),

pub fn init() Builder {
    return .{
        .vertices = .empty,
        .indices = .empty,
        .normals = .empty,
        .hm = .empty,
    };
}

pub fn initCapacity(alloc: Allocator, triangles: usize) !Builder {
    var b: Builder = .init();
    errdefer b.deinit(alloc);
    try b.vertices.ensureTotalCapacity(alloc, triangles * 3);
    try b.indices.ensureTotalCapacity(alloc, triangles * 3);
    try b.normals.ensureTotalCapacity(alloc, triangles);
    try b.hm.ensureTotalCapacity(alloc, @intCast(triangles * 3));
    return b;
}

pub fn deinit(self: *Builder, alloc: Allocator) void {
    self.vertices.deinit(alloc);
    self.indices.deinit(alloc);
    self.normals.deinit(alloc);
    self.hm.deinit(alloc);
}

pub fn vertexIndex(self: *Builder, alloc: Allocator, v: Vector3) !usize {
    const key: [12]u8 = @bitCast(v);
    const gop = try self.hm.getOrPut(alloc, key);
    if (!gop.found_existing) {
        gop.value_ptr.* = self.vertices.items.len;
        try self.vertices.append(alloc, v);
    }
    return gop.value_ptr.*;
}

pub fn addTriangle(self: *Builder, alloc: Allocator, a: Vector3, b: Vector3, c: Vector3, n: Vector3) !void {
    try self.indices.append(alloc, try self.vertexIndex(alloc, a));
    try self.indices.append(alloc, try self.vertexIndex(alloc, b));
    try self.indices.append(alloc, try self.vertexIndex(alloc, c));
    try self.normals.append(alloc, n);
}

pub fn addQuad(self: *Builder, alloc: Allocator, a: Vector3, b: Vector3, c: Vector3, d: Vector3) !void {
    try self.addTriangle(alloc, a, b, c, triangleNormal(a, b, c));
    try self.addTriangle(alloc, a, c, d, triangleNormal(a, c, d));
}

/// Consume the builder and produce an owned Mesh.
pub fn toMesh(self: *Builder, alloc: Allocator) !Mesh {
    const verts = try self.vertices.toOwnedSlice(alloc);
    errdefer alloc.free(verts);
    const inds = try self.indices.toOwnedSlice(alloc);
    errdefer alloc.free(inds);
    const norms = try self.normals.toOwnedSlice(alloc);
    self.hm.deinit(alloc);
    return .{
        .vertices = verts,
        .indices = inds,
        .normals = norms,
        .triangles_count = norms.len,
    };
}

const testing = std.testing;

test "vertexIndex assigns and deduplicates" {
    const alloc = testing.allocator;
    var b: Builder = .init();
    defer b.deinit(alloc);

    try testing.expectEqual(@as(usize, 0), try b.vertexIndex(alloc, .init(0, 0, 0)));
    try testing.expectEqual(@as(usize, 1), try b.vertexIndex(alloc, .init(1, 0, 0)));
    try testing.expectEqual(@as(usize, 0), try b.vertexIndex(alloc, .init(0, 0, 0))); // dedup
    try testing.expectEqual(@as(usize, 2), b.vertices.items.len);

    try testing.expectEqual(@as(usize, 2), try b.vertexIndex(alloc, .init(-0.0, 0, 0)));
}

test "addTriangle and addQuad share vertices and record normals" {
    const alloc = testing.allocator;
    var b: Builder = .init();
    defer b.deinit(alloc);

    try b.addTriangle(alloc, .init(0, 0, 0), .init(1, 0, 0), .init(0, 1, 0), .init(0, 0, 1));
    try testing.expectEqualSlices(usize, &.{ 0, 1, 2 }, b.indices.items);
    try testing.expect(b.normals.items[0].eql(.init(0, 0, 1)));

    try b.addQuad(alloc, .init(0, 0, 0), .init(2, 0, 0), .init(2, 2, 0), .init(0, 2, 0));
    try testing.expectEqual(@as(usize, 6), b.vertices.items.len);
    try testing.expectEqual(@as(usize, 3), b.normals.items.len);
    try testing.expect(b.normals.items[1].eql(.init(0, 0, 1)));
    try testing.expect(b.normals.items[2].eql(.init(0, 0, 1)));
}

test "initCapacity reserves room and stays usable" {
    const alloc = testing.allocator;
    var b: Builder = try .initCapacity(alloc, 2);
    defer b.deinit(alloc);

    try testing.expect(b.vertices.capacity >= 6 and b.normals.capacity >= 2);
    try b.addTriangle(alloc, .init(0, 0, 0), .init(1, 0, 0), .init(0, 1, 0), .init(0, 0, 1));
    try testing.expectEqual(@as(usize, 1), b.normals.items.len);
}

test "toMesh hands ownership to an owned mesh" {
    const alloc = testing.allocator;
    const mesh = build: {
        var b: Builder = .init();
        errdefer b.deinit(alloc);
        try b.addQuad(alloc, .init(0, 0, 0), .init(1, 0, 0), .init(1, 1, 0), .init(0, 1, 0));
        break :build try b.toMesh(alloc);
    };
    defer mesh.deinit(alloc);

    try testing.expectEqual(@as(usize, 2), mesh.triangles_count);
    try testing.expectEqual(mesh.triangles_count, mesh.normals.len);
    try testing.expectEqual(@as(usize, 4), mesh.vertices.len);
    try testing.expectEqualSlices(usize, &.{ 0, 1, 2, 0, 2, 3 }, mesh.indices);
}

test "triangleNormal: unit length, winding, and degenerate cases" {
    const n = triangleNormal(.init(0, 0, 0), .init(1, 0, 0), .init(0, 1, 0));
    try testing.expect(n.approxEql(.init(0, 0, 1), 1e-6));

    const flipped = triangleNormal(.init(0, 0, 0), .init(0, 1, 0), .init(1, 0, 0));
    try testing.expect(flipped.approxEql(n.negate(), 1e-6));

    const a: Vector3 = .init(1, 2, 3);
    const b: Vector3 = .init(4, 0, -1);
    const c: Vector3 = .init(-2, 5, 2);
    const m = triangleNormal(a, b, c);
    try testing.expectApproxEqAbs(@as(f32, 1), m.length(), 1e-5);
    try testing.expectApproxEqAbs(@as(f32, 0), m.dot(b.sub(a)), 1e-4);

    try testing.expect(triangleNormal(.init(0, 0, 0), .init(1, 1, 1), .init(2, 2, 2)).eql(.zero));
}
