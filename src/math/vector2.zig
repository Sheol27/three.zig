const std = @import("std");

pub const Vector2 = extern struct {
    x: f32,
    y: f32,

    pub const zero = Vector2{ .x = 0, .y = 0 };
    pub const one = Vector2{ .x = 1, .y = 1 };
    pub const unit_x = Vector2{ .x = 1, .y = 0 };
    pub const unit_y = Vector2{ .x = 0, .y = 1 };

    pub fn init(x: f32, y: f32) Vector2 {
        return .{ .x = x, .y = y };
    }

    pub fn splat(s: f32) Vector2 {
        return .{ .x = s, .y = s };
    }

    pub fn add(self: Vector2, other: Vector2) Vector2 {
        return .{
            .x = self.x + other.x,
            .y = self.y + other.y,
        };
    }

    pub fn sub(self: Vector2, other: Vector2) Vector2 {
        return .{
            .x = self.x - other.x,
            .y = self.y - other.y,
        };
    }

    pub fn mul(self: Vector2, other: Vector2) Vector2 {
        return .{
            .x = self.x * other.x,
            .y = self.y * other.y,
        };
    }

    pub fn div(self: Vector2, other: Vector2) Vector2 {
        return .{
            .x = self.x / other.x,
            .y = self.y / other.y,
        };
    }

    pub fn addScalar(self: Vector2, s: f32) Vector2 {
        return .{
            .x = self.x + s,
            .y = self.y + s,
        };
    }

    pub fn subScalar(self: Vector2, s: f32) Vector2 {
        return .{
            .x = self.x - s,
            .y = self.y - s,
        };
    }

    pub fn mulScalar(self: Vector2, s: f32) Vector2 {
        return .{
            .x = self.x * s,
            .y = self.y * s,
        };
    }

    pub fn divScalar(self: Vector2, s: f32) Vector2 {
        return .{
            .x = self.x / s,
            .y = self.y / s,
        };
    }

    pub fn negate(self: Vector2) Vector2 {
        return .{ .x = -self.x, .y = -self.y };
    }

    pub fn abs(self: Vector2) Vector2 {
        return .{ .x = @abs(self.x), .y = @abs(self.y) };
    }

    pub fn dot(self: Vector2, other: Vector2) f32 {
        return self.x * other.x + self.y * other.y;
    }

    pub fn cross(self: Vector2, other: Vector2) f32 {
        return self.x * other.y - self.y * other.x;
    }

    pub fn lengthSquared(self: Vector2) f32 {
        return self.dot(self);
    }

    pub fn length(self: Vector2) f32 {
        return @sqrt(self.lengthSquared());
    }

    pub fn normalize(self: Vector2) Vector2 {
        const len_sq = self.lengthSquared();
        if (len_sq == 0) return Vector2.zero;
        return self.mulScalar(1.0 / @sqrt(len_sq));
    }

    pub fn distance(self: Vector2, other: Vector2) f32 {
        return self.sub(other).length();
    }

    pub fn distanceSquared(self: Vector2, other: Vector2) f32 {
        return self.sub(other).lengthSquared();
    }

    pub fn lerp(self: Vector2, other: Vector2, t: f32) Vector2 {
        return .{
            .x = self.x + (other.x - self.x) * t,
            .y = self.y + (other.y - self.y) * t,
        };
    }

    pub fn min(self: Vector2, other: Vector2) Vector2 {
        return .{
            .x = @min(self.x, other.x),
            .y = @min(self.y, other.y),
        };
    }

    pub fn max(self: Vector2, other: Vector2) Vector2 {
        return .{
            .x = @max(self.x, other.x),
            .y = @max(self.y, other.y),
        };
    }

    pub fn clamp(self: Vector2, lo: Vector2, hi: Vector2) Vector2 {
        return self.max(lo).min(hi);
    }

    pub fn eql(self: Vector2, other: Vector2) bool {
        return self.x == other.x and self.y == other.y;
    }

    pub fn approxEql(self: Vector2, other: Vector2, tolerance: f32) bool {
        return @abs(self.x - other.x) <= tolerance and
            @abs(self.y - other.y) <= tolerance;
    }
};

test "basic operations" {
    const a = Vector2.init(1, 2);
    const b = Vector2.init(4, 5);

    try std.testing.expect(a.add(b).eql(Vector2.init(5, 7)));
    try std.testing.expect(a.sub(b).eql(Vector2.init(-3, -3)));
    try std.testing.expectEqual(@as(f32, 14), a.dot(b));
    try std.testing.expect(Vector2.unit_x.mulScalar(3).normalize().eql(Vector2.unit_x));
}

test "constants" {
    try std.testing.expect(Vector2.zero.eql(Vector2.init(0, 0)));
    try std.testing.expect(Vector2.one.eql(Vector2.init(1, 1)));
    try std.testing.expect(Vector2.unit_x.eql(Vector2.init(1, 0)));
    try std.testing.expect(Vector2.unit_y.eql(Vector2.init(0, 1)));
}

test "init and splat" {
    const v = Vector2.init(1, 2);
    try std.testing.expectEqual(@as(f32, 1), v.x);
    try std.testing.expectEqual(@as(f32, 2), v.y);
    try std.testing.expect(Vector2.splat(5).eql(Vector2.init(5, 5)));
}

test "componentwise mul and div" {
    const a = Vector2.init(1, 2);
    const b = Vector2.init(4, 5);
    try std.testing.expect(a.mul(b).eql(Vector2.init(4, 10)));
    try std.testing.expect(Vector2.init(6, 8).div(Vector2.init(2, 4)).eql(Vector2.init(3, 2)));
}

test "mulScalar, negate, abs" {
    const a = Vector2.init(1, -2);
    try std.testing.expect(a.mulScalar(2).eql(Vector2.init(2, -4)));
    try std.testing.expect(a.mulScalar(0).eql(Vector2.zero));
    try std.testing.expect(a.negate().eql(Vector2.init(-1, 2)));
    try std.testing.expect(a.abs().eql(Vector2.init(1, 2)));
}

test "length and lengthSquared" {
    const v = Vector2.init(3, 4);
    try std.testing.expectEqual(@as(f32, 25), v.lengthSquared());
    try std.testing.expectApproxEqAbs(@as(f32, 5), v.length(), 1e-5);
    try std.testing.expectEqual(@as(f32, 0), Vector2.zero.length());
}

test "normalize" {
    try std.testing.expect(Vector2.zero.normalize().eql(Vector2.zero));
    try std.testing.expect(Vector2.init(0, 3).normalize().approxEql(Vector2.unit_y, 1e-6));
    const n = Vector2.init(1, -2).normalize();
    try std.testing.expectApproxEqAbs(@as(f32, 1), n.length(), 1e-5);
}

test "distance and distanceSquared" {
    const a = Vector2.init(1, 2);
    const b = Vector2.init(4, 6);
    try std.testing.expectApproxEqAbs(@as(f32, 5), a.distance(b), 1e-5);
    try std.testing.expectEqual(@as(f32, 25), a.distanceSquared(b));
    try std.testing.expectEqual(@as(f32, 0), a.distance(a));
}

test "lerp" {
    const a = Vector2.init(1, 2);
    const b = Vector2.init(4, 5);
    try std.testing.expect(a.lerp(b, 0).eql(a));
    try std.testing.expect(a.lerp(b, 1).eql(b));
    try std.testing.expect(a.lerp(b, 0.5).eql(Vector2.init(2.5, 3.5)));
}

test "min, max, clamp" {
    const a = Vector2.init(1, 5);
    const b = Vector2.init(4, 2);
    try std.testing.expect(a.min(b).eql(Vector2.init(1, 2)));
    try std.testing.expect(a.max(b).eql(Vector2.init(4, 5)));
    const c = Vector2.init(-1, 0.5);
    try std.testing.expect(c.clamp(Vector2.zero, Vector2.one).eql(Vector2.init(0, 0.5)));
}

test "eql and approxEql" {
    const a = Vector2.init(1, 2);
    try std.testing.expect(a.eql(Vector2.init(1, 2)));
    try std.testing.expect(!a.eql(Vector2.init(1, 2.0001)));
    try std.testing.expect(a.approxEql(Vector2.init(1.00001, 2.00001), 1e-3));
    try std.testing.expect(!a.approxEql(Vector2.init(1.5, 2), 1e-3));
}

test "cross sign and degenerate cases" {
    try std.testing.expectEqual(@as(f32, 1), Vector2.unit_x.cross(Vector2.unit_y));
    try std.testing.expectEqual(@as(f32, -1), Vector2.unit_y.cross(Vector2.unit_x));
    try std.testing.expectEqual(@as(f32, 0), Vector2.init(2, 4).cross(Vector2.init(1, 2)));
    const a = Vector2.init(1, 2);
    const b = Vector2.init(-2, 5);
    try std.testing.expectEqual(a.cross(b), -b.cross(a));
}
