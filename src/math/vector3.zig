const std = @import("std");
const matrix4 = @import("matrix4.zig");

pub fn Vector3(comptime T: type) type {
    switch (@typeInfo(T)) {
        .float, .int => {},
        else => @compileError("Vector3 requires a numeric scalar type, got " ++ @typeName(T)),
    }

    return extern struct {
        const Self = @This();

        x: T,
        y: T,
        z: T,

        pub const zero = Self{ .x = 0, .y = 0, .z = 0 };
        pub const one = Self{ .x = 1, .y = 1, .z = 1 };
        pub const unit_x = Self{ .x = 1, .y = 0, .z = 0 };
        pub const unit_y = Self{ .x = 0, .y = 1, .z = 0 };
        pub const unit_z = Self{ .x = 0, .y = 0, .z = 1 };

        pub fn init(x: T, y: T, z: T) Self {
            return .{ .x = x, .y = y, .z = z };
        }

        pub fn splat(s: T) Self {
            return .{ .x = s, .y = s, .z = s };
        }

        pub fn add(self: Self, other: Self) Self {
            return .{
                .x = self.x + other.x,
                .y = self.y + other.y,
                .z = self.z + other.z,
            };
        }

        pub fn sub(self: Self, other: Self) Self {
            return .{
                .x = self.x - other.x,
                .y = self.y - other.y,
                .z = self.z - other.z,
            };
        }

        pub fn mul(self: Self, other: Self) Self {
            return .{
                .x = self.x * other.x,
                .y = self.y * other.y,
                .z = self.z * other.z,
            };
        }

        pub fn div(self: Self, other: Self) Self {
            comptime assertFloat(T, "div");
            return .{
                .x = self.x / other.x,
                .y = self.y / other.y,
                .z = self.z / other.z,
            };
        }

        pub fn addScalar(self: Self, s: T) Self {
            return .{
                .x = self.x + s,
                .y = self.y + s,
                .z = self.z + s,
            };
        }

        pub fn subScalar(self: Self, s: T) Self {
            return .{
                .x = self.x - s,
                .y = self.y - s,
                .z = self.z - s,
            };
        }

        pub fn mulScalar(self: Self, s: T) Self {
            return .{
                .x = self.x * s,
                .y = self.y * s,
                .z = self.z * s,
            };
        }

        pub fn divScalar(self: Self, s: T) Self {
            comptime assertFloat(T, "divScalar");
            return .{
                .x = self.x / s,
                .y = self.y / s,
                .z = self.z / s,
            };
        }

        pub fn negate(self: Self) Self {
            return .{ .x = -self.x, .y = -self.y, .z = -self.z };
        }

        pub fn abs(self: Self) Self {
            comptime assertFloat(T, "abs");
            return .{ .x = @abs(self.x), .y = @abs(self.y), .z = @abs(self.z) };
        }

        pub fn dot(self: Self, other: Self) T {
            return self.x * other.x + self.y * other.y + self.z * other.z;
        }

        pub fn cross(self: Self, other: Self) Self {
            return .{
                .x = self.y * other.z - self.z * other.y,
                .y = self.z * other.x - self.x * other.z,
                .z = self.x * other.y - self.y * other.x,
            };
        }

        pub fn lengthSquared(self: Self) T {
            return self.dot(self);
        }

        pub fn length(self: Self) T {
            comptime assertFloat(T, "length");
            return @sqrt(self.lengthSquared());
        }

        pub fn normalize(self: Self) Self {
            comptime assertFloat(T, "normalize");
            const len_sq = self.lengthSquared();
            if (len_sq == 0) return zero;
            return self.mulScalar(1.0 / @sqrt(len_sq));
        }

        pub fn distance(self: Self, other: Self) T {
            return self.sub(other).length();
        }

        pub fn distanceSquared(self: Self, other: Self) T {
            return self.sub(other).lengthSquared();
        }

        pub fn lerp(self: Self, other: Self, t: T) Self {
            comptime assertFloat(T, "lerp");
            return .{
                .x = self.x + (other.x - self.x) * t,
                .y = self.y + (other.y - self.y) * t,
                .z = self.z + (other.z - self.z) * t,
            };
        }

        pub fn min(self: Self, other: Self) Self {
            return .{
                .x = @min(self.x, other.x),
                .y = @min(self.y, other.y),
                .z = @min(self.z, other.z),
            };
        }

        pub fn max(self: Self, other: Self) Self {
            return .{
                .x = @max(self.x, other.x),
                .y = @max(self.y, other.y),
                .z = @max(self.z, other.z),
            };
        }

        pub fn clamp(self: Self, lo: Self, hi: Self) Self {
            return self.max(lo).min(hi);
        }

        pub fn eql(self: Self, other: Self) bool {
            return self.x == other.x and self.y == other.y and self.z == other.z;
        }

        pub fn approxEql(self: Self, other: Self, tolerance: T) bool {
            comptime assertFloat(T, "approxEql");
            return @abs(self.x - other.x) <= tolerance and
                @abs(self.y - other.y) <= tolerance and
                @abs(self.z - other.z) <= tolerance;
        }

        // NOTE: this assumes affine matrices, maybe in the future change to homogeneous
        // if perspective is needed
        pub fn transformPoint(self: Self, m: matrix4.Matrix4(T)) Self {
            return .{
                .x = m.m[0][0] * self.x + m.m[1][0] * self.y + m.m[2][0] * self.z + m.m[3][0],
                .y = m.m[0][1] * self.x + m.m[1][1] * self.y + m.m[2][1] * self.z + m.m[3][1],
                .z = m.m[0][2] * self.x + m.m[1][2] * self.y + m.m[2][2] * self.z + m.m[3][2],
            };
        }

        pub fn transformDirection(self: Self, m: matrix4.Matrix4(T)) Self {
            return .{
                .x = m.m[0][0] * self.x + m.m[1][0] * self.y + m.m[2][0] * self.z,
                .y = m.m[0][1] * self.x + m.m[1][1] * self.y + m.m[2][1] * self.z,
                .z = m.m[0][2] * self.x + m.m[1][2] * self.y + m.m[2][2] * self.z,
            };
        }
    };
}

fn assertFloat(comptime T: type, comptime op: []const u8) void {
    if (@typeInfo(T) != .float) {
        @compileError(op ++ " requires a float scalar type, got " ++ @typeName(T));
    }
}

const Vec3 = Vector3(f32);

test "basic operations" {
    const a = Vec3.init(1, 2, 3);
    const b = Vec3.init(4, 5, 6);

    try std.testing.expect(a.add(b).eql(Vec3.init(5, 7, 9)));
    try std.testing.expect(a.sub(b).eql(Vec3.init(-3, -3, -3)));
    try std.testing.expectEqual(@as(f32, 32), a.dot(b));
    try std.testing.expect(a.cross(b).eql(Vec3.init(-3, 6, -3)));
    try std.testing.expect(Vec3.unit_x.mulScalar(3).normalize().eql(Vec3.unit_x));
}

test "constants" {
    try std.testing.expect(Vec3.zero.eql(Vec3.init(0, 0, 0)));
    try std.testing.expect(Vec3.one.eql(Vec3.init(1, 1, 1)));
    try std.testing.expect(Vec3.unit_x.eql(Vec3.init(1, 0, 0)));
    try std.testing.expect(Vec3.unit_y.eql(Vec3.init(0, 1, 0)));
    try std.testing.expect(Vec3.unit_z.eql(Vec3.init(0, 0, 1)));
}

test "init and splat" {
    const v = Vec3.init(1, 2, 3);
    try std.testing.expectEqual(@as(f32, 1), v.x);
    try std.testing.expectEqual(@as(f32, 2), v.y);
    try std.testing.expectEqual(@as(f32, 3), v.z);
    try std.testing.expect(Vec3.splat(5).eql(Vec3.init(5, 5, 5)));
}

test "componentwise mul and div" {
    const a = Vec3.init(1, 2, 3);
    const b = Vec3.init(4, 5, 6);
    try std.testing.expect(a.mul(b).eql(Vec3.init(4, 10, 18)));
    try std.testing.expect(Vec3.init(6, 8, 10).div(Vec3.init(2, 4, 5)).eql(Vec3.init(3, 2, 2)));
}

test "mulScalar, negate, abs" {
    const a = Vec3.init(1, -2, 3);
    try std.testing.expect(a.mulScalar(2).eql(Vec3.init(2, -4, 6)));
    try std.testing.expect(a.mulScalar(0).eql(Vec3.zero));
    try std.testing.expect(a.negate().eql(Vec3.init(-1, 2, -3)));
    try std.testing.expect(a.abs().eql(Vec3.init(1, 2, 3)));
}

test "length and lengthSquared" {
    const v = Vec3.init(2, 3, 6);
    try std.testing.expectEqual(@as(f32, 49), v.lengthSquared());
    try std.testing.expectApproxEqAbs(@as(f32, 7), v.length(), 1e-5);
    try std.testing.expectEqual(@as(f32, 0), Vec3.zero.length());
}

test "normalize" {
    try std.testing.expect(Vec3.zero.normalize().eql(Vec3.zero));
    try std.testing.expect(Vec3.init(0, 3, 0).normalize().approxEql(Vec3.unit_y, 1e-6));
    const n = Vec3.init(1, 2, -2).normalize();
    try std.testing.expectApproxEqAbs(@as(f32, 1), n.length(), 1e-5);
}

test "distance and distanceSquared" {
    const a = Vec3.init(1, 2, 3);
    const b = Vec3.init(4, 6, 3);
    try std.testing.expectApproxEqAbs(@as(f32, 5), a.distance(b), 1e-5);
    try std.testing.expectEqual(@as(f32, 25), a.distanceSquared(b));
    try std.testing.expectEqual(@as(f32, 0), a.distance(a));
}

test "lerp" {
    const a = Vec3.init(1, 2, 3);
    const b = Vec3.init(4, 5, 6);
    try std.testing.expect(a.lerp(b, 0).eql(a));
    try std.testing.expect(a.lerp(b, 1).eql(b));
    try std.testing.expect(a.lerp(b, 0.5).eql(Vec3.init(2.5, 3.5, 4.5)));
}

test "min, max, clamp" {
    const a = Vec3.init(1, 5, 3);
    const b = Vec3.init(4, 2, 6);
    try std.testing.expect(a.min(b).eql(Vec3.init(1, 2, 3)));
    try std.testing.expect(a.max(b).eql(Vec3.init(4, 5, 6)));
    const c = Vec3.init(-1, 5, 0.5);
    try std.testing.expect(c.clamp(Vec3.zero, Vec3.one).eql(Vec3.init(0, 1, 0.5)));
}

test "eql and approxEql" {
    const a = Vec3.init(1, 2, 3);
    try std.testing.expect(a.eql(Vec3.init(1, 2, 3)));
    try std.testing.expect(!a.eql(Vec3.init(1, 2, 3.0001)));
    try std.testing.expect(a.approxEql(Vec3.init(1.00001, 2.00001, 3.00001), 1e-3));
    try std.testing.expect(!a.approxEql(Vec3.init(1.5, 2, 3), 1e-3));
}

test "cross product properties" {
    try std.testing.expect(Vec3.unit_x.cross(Vec3.unit_x).eql(Vec3.zero));
    try std.testing.expect(Vec3.unit_x.cross(Vec3.unit_y).eql(Vec3.unit_z));
    const a = Vec3.init(1, 2, 3);
    const b = Vec3.init(-2, 0, 5);
    const c = a.cross(b);
    try std.testing.expectApproxEqAbs(@as(f32, 0), c.dot(a), 1e-4);
    try std.testing.expectApproxEqAbs(@as(f32, 0), c.dot(b), 1e-4);
}

test "generic scalar types" {
    const Vec3d = Vector3(f64);
    try std.testing.expectEqual(@as(f64, 5), Vec3d.init(3, 4, 0).length());
    try std.testing.expectEqual(@as(f64, 1), Vec3d.init(0, 0, -7).normalize().lengthSquared());

    const Vec3i = Vector3(i32);
    const a = Vec3i.init(1, 2, 3);
    const b = Vec3i.init(4, 5, 6);
    try std.testing.expect(a.add(b).eql(Vec3i.init(5, 7, 9)));
    try std.testing.expectEqual(@as(i32, 32), a.dot(b));
    try std.testing.expect(a.cross(b).eql(Vec3i.init(-3, 6, -3)));
    try std.testing.expect(a.min(b).eql(a));
}
