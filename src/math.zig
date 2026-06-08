const std = @import("std");

pub const Vector3 = extern struct {
    x: f32,
    y: f32,
    z: f32,

    pub const zero = Vector3{ .x = 0, .y = 0, .z = 0 };
    pub const one = Vector3{ .x = 1, .y = 1, .z = 1 };
    pub const unit_x = Vector3{ .x = 1, .y = 0, .z = 0 };
    pub const unit_y = Vector3{ .x = 0, .y = 1, .z = 0 };
    pub const unit_z = Vector3{ .x = 0, .y = 0, .z = 1 };

    pub fn init(x: f32, y: f32, z: f32) Vector3 {
        return .{ .x = x, .y = y, .z = z };
    }

    pub fn splat(s: f32) Vector3 {
        return .{ .x = s, .y = s, .z = s };
    }

    pub fn add(self: Vector3, other: Vector3) Vector3 {
        return .{
            .x = self.x + other.x,
            .y = self.y + other.y,
            .z = self.z + other.z,
        };
    }

    pub fn sub(self: Vector3, other: Vector3) Vector3 {
        return .{
            .x = self.x - other.x,
            .y = self.y - other.y,
            .z = self.z - other.z,
        };
    }

    pub fn mul(self: Vector3, other: Vector3) Vector3 {
        return .{
            .x = self.x * other.x,
            .y = self.y * other.y,
            .z = self.z * other.z,
        };
    }

    pub fn div(self: Vector3, other: Vector3) Vector3 {
        return .{
            .x = self.x / other.x,
            .y = self.y / other.y,
            .z = self.z / other.z,
        };
    }

    pub fn scale(self: Vector3, s: f32) Vector3 {
        return .{ .x = self.x * s, .y = self.y * s, .z = self.z * s };
    }

    pub fn negate(self: Vector3) Vector3 {
        return .{ .x = -self.x, .y = -self.y, .z = -self.z };
    }

    pub fn abs(self: Vector3) Vector3 {
        return .{ .x = @abs(self.x), .y = @abs(self.y), .z = @abs(self.z) };
    }

    pub fn dot(self: Vector3, other: Vector3) f32 {
        return self.x * other.x + self.y * other.y + self.z * other.z;
    }

    pub fn cross(self: Vector3, other: Vector3) Vector3 {
        return .{
            .x = self.y * other.z - self.z * other.y,
            .y = self.z * other.x - self.x * other.z,
            .z = self.x * other.y - self.y * other.x,
        };
    }

    pub fn lengthSquared(self: Vector3) f32 {
        return self.dot(self);
    }

    pub fn length(self: Vector3) f32 {
        return @sqrt(self.lengthSquared());
    }

    pub fn normalize(self: Vector3) Vector3 {
        const len_sq = self.lengthSquared();
        if (len_sq == 0) return Vector3.zero;
        return self.scale(1.0 / @sqrt(len_sq));
    }

    pub fn distance(self: Vector3, other: Vector3) f32 {
        return self.sub(other).length();
    }

    pub fn distanceSquared(self: Vector3, other: Vector3) f32 {
        return self.sub(other).lengthSquared();
    }

    pub fn lerp(self: Vector3, other: Vector3, t: f32) Vector3 {
        return .{
            .x = self.x + (other.x - self.x) * t,
            .y = self.y + (other.y - self.y) * t,
            .z = self.z + (other.z - self.z) * t,
        };
    }

    pub fn min(self: Vector3, other: Vector3) Vector3 {
        return .{
            .x = @min(self.x, other.x),
            .y = @min(self.y, other.y),
            .z = @min(self.z, other.z),
        };
    }

    pub fn max(self: Vector3, other: Vector3) Vector3 {
        return .{
            .x = @max(self.x, other.x),
            .y = @max(self.y, other.y),
            .z = @max(self.z, other.z),
        };
    }

    pub fn clamp(self: Vector3, lo: Vector3, hi: Vector3) Vector3 {
        return self.max(lo).min(hi);
    }

    pub fn eql(self: Vector3, other: Vector3) bool {
        return self.x == other.x and self.y == other.y and self.z == other.z;
    }

    pub fn approxEql(self: Vector3, other: Vector3, tolerance: f32) bool {
        return @abs(self.x - other.x) <= tolerance and
            @abs(self.y - other.y) <= tolerance and
            @abs(self.z - other.z) <= tolerance;
    }
};


test "basic operations" {
    const a = Vector3.init(1, 2, 3);
    const b = Vector3.init(4, 5, 6);

    try std.testing.expect(a.add(b).eql(Vector3.init(5, 7, 9)));
    try std.testing.expect(a.sub(b).eql(Vector3.init(-3, -3, -3)));
    try std.testing.expectEqual(@as(f32, 32), a.dot(b));
    try std.testing.expect(a.cross(b).eql(Vector3.init(-3, 6, -3)));
    try std.testing.expect(Vector3.unit_x.scale(3).normalize().eql(Vector3.unit_x));
}

test "constants" {
    try std.testing.expect(Vector3.zero.eql(Vector3.init(0, 0, 0)));
    try std.testing.expect(Vector3.one.eql(Vector3.init(1, 1, 1)));
    try std.testing.expect(Vector3.unit_x.eql(Vector3.init(1, 0, 0)));
    try std.testing.expect(Vector3.unit_y.eql(Vector3.init(0, 1, 0)));
    try std.testing.expect(Vector3.unit_z.eql(Vector3.init(0, 0, 1)));
}

test "init and splat" {
    const v = Vector3.init(1, 2, 3);
    try std.testing.expectEqual(@as(f32, 1), v.x);
    try std.testing.expectEqual(@as(f32, 2), v.y);
    try std.testing.expectEqual(@as(f32, 3), v.z);
    try std.testing.expect(Vector3.splat(5).eql(Vector3.init(5, 5, 5)));
}

test "componentwise mul and div" {
    const a = Vector3.init(1, 2, 3);
    const b = Vector3.init(4, 5, 6);
    try std.testing.expect(a.mul(b).eql(Vector3.init(4, 10, 18)));
    try std.testing.expect(Vector3.init(6, 8, 10).div(Vector3.init(2, 4, 5)).eql(Vector3.init(3, 2, 2)));
}

test "scale, negate, abs" {
    const a = Vector3.init(1, -2, 3);
    try std.testing.expect(a.scale(2).eql(Vector3.init(2, -4, 6)));
    try std.testing.expect(a.scale(0).eql(Vector3.zero));
    try std.testing.expect(a.negate().eql(Vector3.init(-1, 2, -3)));
    try std.testing.expect(a.abs().eql(Vector3.init(1, 2, 3)));
}

test "length and lengthSquared" {
    const v = Vector3.init(2, 3, 6);
    try std.testing.expectEqual(@as(f32, 49), v.lengthSquared());
    try std.testing.expectApproxEqAbs(@as(f32, 7), v.length(), 1e-5);
    try std.testing.expectEqual(@as(f32, 0), Vector3.zero.length());
}

test "normalize" {
    try std.testing.expect(Vector3.zero.normalize().eql(Vector3.zero));
    try std.testing.expect(Vector3.init(0, 3, 0).normalize().approxEql(Vector3.unit_y, 1e-6));
    const n = Vector3.init(1, 2, -2).normalize();
    try std.testing.expectApproxEqAbs(@as(f32, 1), n.length(), 1e-5);
}

test "distance and distanceSquared" {
    const a = Vector3.init(1, 2, 3);
    const b = Vector3.init(4, 6, 3);
    try std.testing.expectApproxEqAbs(@as(f32, 5), a.distance(b), 1e-5);
    try std.testing.expectEqual(@as(f32, 25), a.distanceSquared(b));
    try std.testing.expectEqual(@as(f32, 0), a.distance(a));
}

test "lerp" {
    const a = Vector3.init(1, 2, 3);
    const b = Vector3.init(4, 5, 6);
    try std.testing.expect(a.lerp(b, 0).eql(a));
    try std.testing.expect(a.lerp(b, 1).eql(b));
    try std.testing.expect(a.lerp(b, 0.5).eql(Vector3.init(2.5, 3.5, 4.5)));
}

test "min, max, clamp" {
    const a = Vector3.init(1, 5, 3);
    const b = Vector3.init(4, 2, 6);
    try std.testing.expect(a.min(b).eql(Vector3.init(1, 2, 3)));
    try std.testing.expect(a.max(b).eql(Vector3.init(4, 5, 6)));
    const c = Vector3.init(-1, 5, 0.5);
    try std.testing.expect(c.clamp(Vector3.zero, Vector3.one).eql(Vector3.init(0, 1, 0.5)));
}

test "eql and approxEql" {
    const a = Vector3.init(1, 2, 3);
    try std.testing.expect(a.eql(Vector3.init(1, 2, 3)));
    try std.testing.expect(!a.eql(Vector3.init(1, 2, 3.0001)));
    try std.testing.expect(a.approxEql(Vector3.init(1.00001, 2.00001, 3.00001), 1e-3));
    try std.testing.expect(!a.approxEql(Vector3.init(1.5, 2, 3), 1e-3));
}

test "cross product properties" {
    try std.testing.expect(Vector3.unit_x.cross(Vector3.unit_x).eql(Vector3.zero));
    try std.testing.expect(Vector3.unit_x.cross(Vector3.unit_y).eql(Vector3.unit_z));
    const a = Vector3.init(1, 2, 3);
    const b = Vector3.init(-2, 0, 5);
    const c = a.cross(b);
    try std.testing.expectApproxEqAbs(@as(f32, 0), c.dot(a), 1e-4);
    try std.testing.expectApproxEqAbs(@as(f32, 0), c.dot(b), 1e-4);
}
