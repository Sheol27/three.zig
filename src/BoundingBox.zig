const math = @import("math.zig");
const Vector3 = math.Vector3;
const BoundingBox = @This();

min: Vector3,
max: Vector3,

pub fn center(self: *const BoundingBox) Vector3 {
    return self.max.add(self.min).divScalar(2);
}
