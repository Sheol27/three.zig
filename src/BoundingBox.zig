const std = @import("std");
const math = @import("math.zig");
const Vector3 = math.Vector3;
const BoundingBox = @This();

min: Vector3,
max: Vector3,

pub fn center(self: *const BoundingBox) Vector3 {
    return self.max.add(self.min).divScalar(2);
}

test "center is the midpoint of min and max" {
    const bb: BoundingBox = .{ .min = .init(0, 0, 0), .max = .init(2, 4, 6) };
    try std.testing.expect(bb.center().eql(.init(1, 2, 3)));
}

test "center handles boxes straddling the origin" {
    const bb: BoundingBox = .{ .min = .init(-1, -2, -3), .max = .init(1, 2, 3) };
    try std.testing.expect(bb.center().eql(.init(0, 0, 0)));
}

test "center of a degenerate box is the point itself" {
    const p: Vector3 = .init(5, -7, 9);
    const bb: BoundingBox = .{ .min = p, .max = p };
    try std.testing.expect(bb.center().eql(p));
}
