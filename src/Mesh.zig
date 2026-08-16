const std = @import("std");
const math = @import("math.zig");
const BoundingBox = @import("BoundingBox.zig");
const Vector3 = math.Vector3(f32);
const Allocator = std.mem.Allocator;

pub const Mesh = @This();

vertices: []Vector3,
indices: []usize,
normals: []Vector3,
triangles_count: usize,

/// Return the three vertices of the triangle.
pub fn getTriangle(self: *const Mesh, index: usize) [3]Vector3 {
    return .{
        self.vertices[self.indices[index * 3]],
        self.vertices[self.indices[index * 3 + 1]],
        self.vertices[self.indices[index * 3 + 2]],
    };
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

test "getTriangle returns the vertices of any triangle" {
    var vertices = [_]Vector3{ .init(0, 0, 0), .init(1, 0, 0), .init(1, 1, 0), .init(0, 1, 0) };
    var indices = [_]usize{ 0, 1, 2, 0, 2, 3 };
    var normals = [_]Vector3{ .init(0, 0, 1), .init(0, 0, 1) };
    const mesh: Mesh = .{
        .vertices = &vertices,
        .indices = &indices,
        .normals = &normals,
        .triangles_count = 2,
    };

    const first = mesh.getTriangle(0);
    try std.testing.expect(first[0].eql(.init(0, 0, 0)));
    try std.testing.expect(first[1].eql(.init(1, 0, 0)));
    try std.testing.expect(first[2].eql(.init(1, 1, 0)));

    const second = mesh.getTriangle(1);
    try std.testing.expect(second[0].eql(.init(0, 0, 0)));
    try std.testing.expect(second[1].eql(.init(1, 1, 0)));
    try std.testing.expect(second[2].eql(.init(0, 1, 0)));
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
