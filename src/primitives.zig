const std = @import("std");
const Allocator = std.mem.Allocator;
const Mesh = @import("Mesh.zig");
const Builder = @import("Builder.zig");
const math = @import("math.zig");
const Vector3 = math.Vector3;
const triangleNormal = @import("utils.zig").triangleNormal;

/// Axis-aligned box centered on the origin with the given side lengths.
pub fn box(alloc: Allocator, sx: f32, sy: f32, sz: f32) !Mesh {
    const x = sx / 2;
    const y = sy / 2;
    const z = sz / 2;

    var b: Builder = .init();
    errdefer b.deinit(alloc);

    const v000: Vector3 = .init(-x, -y, -z);
    const v100: Vector3 = .init(x, -y, -z);
    const v110: Vector3 = .init(x, y, -z);
    const v010: Vector3 = .init(-x, y, -z);
    const v001: Vector3 = .init(-x, -y, z);
    const v101: Vector3 = .init(x, -y, z);
    const v111: Vector3 = .init(x, y, z);
    const v011: Vector3 = .init(-x, y, z);

    try b.addQuad(alloc, v001, v101, v111, v011); // +z front
    try b.addQuad(alloc, v100, v000, v010, v110); // -z back
    try b.addQuad(alloc, v101, v100, v110, v111); // +x right
    try b.addQuad(alloc, v000, v001, v011, v010); // -x left
    try b.addQuad(alloc, v011, v111, v110, v010); // +y top
    try b.addQuad(alloc, v001, v000, v100, v101); // -y bottom

    return b.toMesh(alloc);
}

/// Cube centered on the origin with the given side length.
pub fn cube(alloc: Allocator, size: f32) !Mesh {
    return box(alloc, size, size, size);
}

/// Square pyramid. Base sits on the y = 0 plane centered on the origin,
/// apex points up along +y.
pub fn pyramid(alloc: Allocator, base: f32, height: f32) !Mesh {
    const h = base / 2;
    const corners = [4]Vector3{
        .init(-h, 0, -h),
        .init(h, 0, -h),
        .init(h, 0, h),
        .init(-h, 0, h),
    };
    const apex: Vector3 = .init(0, height, 0);

    var b: Builder = .init();
    errdefer b.deinit(alloc);

    // base (faces down, -y)
    try b.addQuad(alloc, corners[0], corners[1], corners[2], corners[3]);
    // four slanted sides
    for (0..4) |i| {
        const n = triangleNormal(corners[(i + 1) % 4], corners[i], apex);
        try b.addTriangle(alloc, corners[(i + 1) % 4], corners[i], apex, n);
    }

    return b.toMesh(alloc);
}

/// Regular tetrahedron centered on the origin. `scale` multiplies the
/// canonical unit coordinates.
pub fn tetrahedron(alloc: Allocator, scale: f32) !Mesh {
    const t0: Vector3 = .init(scale, scale, scale);
    const t1: Vector3 = .init(scale, -scale, -scale);
    const t2: Vector3 = .init(-scale, scale, -scale);
    const t3: Vector3 = .init(-scale, -scale, scale);

    var b: Builder = .init();
    errdefer b.deinit(alloc);

    const n1 = triangleNormal(t0, t1, t2);
    try b.addTriangle(alloc, t0, t1, t2, n1);
    const n2 = triangleNormal(t0, t3, t1);
    try b.addTriangle(alloc, t0, t3, t1, n2);
    const n3 = triangleNormal(t0, t2, t3);
    try b.addTriangle(alloc, t0, t2, t3, n3);
    const n4 = triangleNormal(t1, t3, t2);
    try b.addTriangle(alloc, t1, t3, t2, n4);

    return b.toMesh(alloc);
}

/// Flat square on the y = 0 plane, centered on the origin, normal facing +y.
pub fn plane(alloc: Allocator, size: f32) !Mesh {
    const h = size / 2;
    var b: Builder = .init();
    errdefer b.deinit(alloc);
    try b.addQuad(
        alloc,
        .init(-h, 0, -h),
        .init(-h, 0, h),
        .init(h, 0, h),
        .init(h, 0, -h),
    );
    return b.toMesh(alloc);
}

const testing = std.testing;

test "box: vertex count, triangle count, and bounding box" {
    const alloc = testing.allocator;
    const mesh = try box(alloc, 2, 4, 6);
    defer mesh.deinit(alloc);

    try testing.expectEqual(@as(usize, 8), mesh.vertices.len);
    try testing.expectEqual(@as(usize, 12), mesh.triangles_count);
    try testing.expectEqual(@as(usize, 36), mesh.indices.len);

    const bb = mesh.computeBoundingBox();
    try testing.expect(bb.min.eql(.init(-1, -2, -3)));
    try testing.expect(bb.max.eql(.init(1, 2, 3)));
}

test "box: each face's two triangles share a normal pointing along the face axis" {
    const alloc = testing.allocator;
    const mesh = try box(alloc, 2, 2, 2);
    defer mesh.deinit(alloc);

    const expected = [_]Vector3{
        Vector3.unit_z, Vector3.unit_z.negate(),
        Vector3.unit_x, Vector3.unit_x.negate(),
        Vector3.unit_y, Vector3.unit_y.negate(),
    };
    for (expected, 0..) |n, face| {
        try testing.expect(mesh.normals[face * 2].approxEql(n, 1e-6));
        try testing.expect(mesh.normals[face * 2 + 1].approxEql(n, 1e-6));
    }
}

test "cube: delegates to box with equal sides" {
    const alloc = testing.allocator;
    const mesh = try cube(alloc, 3);
    defer mesh.deinit(alloc);

    const bb = mesh.computeBoundingBox();
    try testing.expect(bb.min.eql(.splat(-1.5)));
    try testing.expect(bb.max.eql(.splat(1.5)));
}

test "pyramid: 5 vertices, 6 triangles, apex above origin" {
    const alloc = testing.allocator;
    const mesh = try pyramid(alloc, 2, 3);
    defer mesh.deinit(alloc);

    try testing.expectEqual(@as(usize, 5), mesh.vertices.len);
    try testing.expectEqual(@as(usize, 6), mesh.triangles_count);

    const bb = mesh.computeBoundingBox();
    try testing.expect(bb.min.eql(.init(-1, 0, -1)));
    try testing.expect(bb.max.eql(.init(1, 3, 1)));

    for (mesh.normals[2..]) |n| {
        try testing.expect(n.y > 0);
    }
}

test "tetrahedron: 4 vertices, 4 triangles, outward-pointing normals" {
    const alloc = testing.allocator;
    const mesh = try tetrahedron(alloc, 1);
    defer mesh.deinit(alloc);

    try testing.expectEqual(@as(usize, 4), mesh.vertices.len);
    try testing.expectEqual(@as(usize, 4), mesh.triangles_count);

    for (0..mesh.triangles_count) |i| {
        const t = mesh.getTriangle(i * 3);
        const centroid = t[0].add(t[1]).add(t[2]).scale(1.0 / 3.0);
        try testing.expect(mesh.normals[i].dot(centroid) > 0);
        try testing.expectApproxEqAbs(@as(f32, 1), mesh.normals[i].length(), 1e-5);
    }
}

test "plane: 4 vertices, 2 triangles, normals facing +y" {
    const alloc = testing.allocator;
    const mesh = try plane(alloc, 4);
    defer mesh.deinit(alloc);

    try testing.expectEqual(@as(usize, 4), mesh.vertices.len);
    try testing.expectEqual(@as(usize, 2), mesh.triangles_count);

    try testing.expect(mesh.normals[0].approxEql(.unit_y, 1e-6));
    try testing.expect(mesh.normals[1].approxEql(.unit_y, 1e-6));

    const bb = mesh.computeBoundingBox();
    try testing.expect(bb.min.eql(.init(-2, 0, -2)));
    try testing.expect(bb.max.eql(.init(2, 0, 2)));
}
