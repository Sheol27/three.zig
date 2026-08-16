const std = @import("std");

pub fn Vector2(comptime T: type) type {
    switch (@typeInfo(T)) {
        .float, .int => {},
        else => @compileError("Vector2 requires a numeric scalar type, got " ++ @typeName(T)),
    }

    return extern struct {
        const Self = @This();

        x: T,
        y: T,

        pub const zero = Self{ .x = 0, .y = 0 };
        pub const one = Self{ .x = 1, .y = 1 };
        pub const unit_x = Self{ .x = 1, .y = 0 };
        pub const unit_y = Self{ .x = 0, .y = 1 };

        pub fn init(x: T, y: T) Self {
            return .{ .x = x, .y = y };
        }

        pub fn splat(s: T) Self {
            return .{ .x = s, .y = s };
        }

        pub fn add(self: Self, other: Self) Self {
            return .{
                .x = self.x + other.x,
                .y = self.y + other.y,
            };
        }

        pub fn sub(self: Self, other: Self) Self {
            return .{
                .x = self.x - other.x,
                .y = self.y - other.y,
            };
        }

        pub fn mul(self: Self, other: Self) Self {
            return .{
                .x = self.x * other.x,
                .y = self.y * other.y,
            };
        }

        pub fn div(self: Self, other: Self) Self {
            comptime assertFloat(T, "div");
            return .{
                .x = self.x / other.x,
                .y = self.y / other.y,
            };
        }

        pub fn addScalar(self: Self, s: T) Self {
            return .{
                .x = self.x + s,
                .y = self.y + s,
            };
        }

        pub fn subScalar(self: Self, s: T) Self {
            return .{
                .x = self.x - s,
                .y = self.y - s,
            };
        }

        pub fn mulScalar(self: Self, s: T) Self {
            return .{
                .x = self.x * s,
                .y = self.y * s,
            };
        }

        pub fn divScalar(self: Self, s: T) Self {
            comptime assertFloat(T, "divScalar");
            return .{
                .x = self.x / s,
                .y = self.y / s,
            };
        }

        pub fn negate(self: Self) Self {
            return .{ .x = -self.x, .y = -self.y };
        }

        pub fn abs(self: Self) Self {
            comptime assertFloat(T, "abs");
            return .{ .x = @abs(self.x), .y = @abs(self.y) };
        }

        pub fn dot(self: Self, other: Self) T {
            return self.x * other.x + self.y * other.y;
        }

        pub fn cross(self: Self, other: Self) T {
            return self.x * other.y - self.y * other.x;
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
            };
        }

        pub fn min(self: Self, other: Self) Self {
            return .{
                .x = @min(self.x, other.x),
                .y = @min(self.y, other.y),
            };
        }

        pub fn max(self: Self, other: Self) Self {
            return .{
                .x = @max(self.x, other.x),
                .y = @max(self.y, other.y),
            };
        }

        pub fn clamp(self: Self, lo: Self, hi: Self) Self {
            return self.max(lo).min(hi);
        }

        pub fn eql(self: Self, other: Self) bool {
            return self.x == other.x and self.y == other.y;
        }

        pub fn approxEql(self: Self, other: Self, tolerance: T) bool {
            comptime assertFloat(T, "approxEql");
            return @abs(self.x - other.x) <= tolerance and
                @abs(self.y - other.y) <= tolerance;
        }
    };
}

fn assertFloat(comptime T: type, comptime op: []const u8) void {
    if (@typeInfo(T) != .float) {
        @compileError(op ++ " requires a float scalar type, got " ++ @typeName(T));
    }
}

const Vec2 = Vector2(f32);

test "basic operations" {
    const a = Vec2.init(1, 2);
    const b = Vec2.init(4, 5);

    try std.testing.expect(a.add(b).eql(Vec2.init(5, 7)));
    try std.testing.expect(a.sub(b).eql(Vec2.init(-3, -3)));
    try std.testing.expectEqual(@as(f32, 14), a.dot(b));
    try std.testing.expect(Vec2.unit_x.mulScalar(3).normalize().eql(Vec2.unit_x));
}

test "constants" {
    try std.testing.expect(Vec2.zero.eql(Vec2.init(0, 0)));
    try std.testing.expect(Vec2.one.eql(Vec2.init(1, 1)));
    try std.testing.expect(Vec2.unit_x.eql(Vec2.init(1, 0)));
    try std.testing.expect(Vec2.unit_y.eql(Vec2.init(0, 1)));
}

test "init and splat" {
    const v = Vec2.init(1, 2);
    try std.testing.expectEqual(@as(f32, 1), v.x);
    try std.testing.expectEqual(@as(f32, 2), v.y);
    try std.testing.expect(Vec2.splat(5).eql(Vec2.init(5, 5)));
}

test "componentwise mul and div" {
    const a = Vec2.init(1, 2);
    const b = Vec2.init(4, 5);
    try std.testing.expect(a.mul(b).eql(Vec2.init(4, 10)));
    try std.testing.expect(Vec2.init(6, 8).div(Vec2.init(2, 4)).eql(Vec2.init(3, 2)));
}

test "mulScalar, negate, abs" {
    const a = Vec2.init(1, -2);
    try std.testing.expect(a.mulScalar(2).eql(Vec2.init(2, -4)));
    try std.testing.expect(a.mulScalar(0).eql(Vec2.zero));
    try std.testing.expect(a.negate().eql(Vec2.init(-1, 2)));
    try std.testing.expect(a.abs().eql(Vec2.init(1, 2)));
}

test "length and lengthSquared" {
    const v = Vec2.init(3, 4);
    try std.testing.expectEqual(@as(f32, 25), v.lengthSquared());
    try std.testing.expectApproxEqAbs(@as(f32, 5), v.length(), 1e-5);
    try std.testing.expectEqual(@as(f32, 0), Vec2.zero.length());
}

test "normalize" {
    try std.testing.expect(Vec2.zero.normalize().eql(Vec2.zero));
    try std.testing.expect(Vec2.init(0, 3).normalize().approxEql(Vec2.unit_y, 1e-6));
    const n = Vec2.init(1, -2).normalize();
    try std.testing.expectApproxEqAbs(@as(f32, 1), n.length(), 1e-5);
}

test "distance and distanceSquared" {
    const a = Vec2.init(1, 2);
    const b = Vec2.init(4, 6);
    try std.testing.expectApproxEqAbs(@as(f32, 5), a.distance(b), 1e-5);
    try std.testing.expectEqual(@as(f32, 25), a.distanceSquared(b));
    try std.testing.expectEqual(@as(f32, 0), a.distance(a));
}

test "lerp" {
    const a = Vec2.init(1, 2);
    const b = Vec2.init(4, 5);
    try std.testing.expect(a.lerp(b, 0).eql(a));
    try std.testing.expect(a.lerp(b, 1).eql(b));
    try std.testing.expect(a.lerp(b, 0.5).eql(Vec2.init(2.5, 3.5)));
}

test "min, max, clamp" {
    const a = Vec2.init(1, 5);
    const b = Vec2.init(4, 2);
    try std.testing.expect(a.min(b).eql(Vec2.init(1, 2)));
    try std.testing.expect(a.max(b).eql(Vec2.init(4, 5)));
    const c = Vec2.init(-1, 0.5);
    try std.testing.expect(c.clamp(Vec2.zero, Vec2.one).eql(Vec2.init(0, 0.5)));
}

test "eql and approxEql" {
    const a = Vec2.init(1, 2);
    try std.testing.expect(a.eql(Vec2.init(1, 2)));
    try std.testing.expect(!a.eql(Vec2.init(1, 2.0001)));
    try std.testing.expect(a.approxEql(Vec2.init(1.00001, 2.00001), 1e-3));
    try std.testing.expect(!a.approxEql(Vec2.init(1.5, 2), 1e-3));
}

test "cross sign and degenerate cases" {
    try std.testing.expectEqual(@as(f32, 1), Vec2.unit_x.cross(Vec2.unit_y));
    try std.testing.expectEqual(@as(f32, -1), Vec2.unit_y.cross(Vec2.unit_x));
    try std.testing.expectEqual(@as(f32, 0), Vec2.init(2, 4).cross(Vec2.init(1, 2)));
    const a = Vec2.init(1, 2);
    const b = Vec2.init(-2, 5);
    try std.testing.expectEqual(a.cross(b), -b.cross(a));
}

test "generic scalar types" {
    const Vec2d = Vector2(f64);
    try std.testing.expectEqual(@as(f64, 5), Vec2d.init(3, 4).length());

    const Vec2i = Vector2(i32);
    const a = Vec2i.init(2, 3);
    const b = Vec2i.init(4, 5);
    try std.testing.expect(a.add(b).eql(Vec2i.init(6, 8)));
    try std.testing.expectEqual(@as(i32, 23), a.dot(b));
    try std.testing.expectEqual(@as(i32, -2), a.cross(b));
}
