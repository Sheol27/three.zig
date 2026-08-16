const std = @import("std");
const vector3 = @import("vector3.zig");

pub fn Matrix4(comptime T: type) type {
    if (@typeInfo(T) != .float) {
        @compileError("Matrix4 requires a float scalar type, got " ++ @typeName(T));
    }

    return extern struct {
        const Self = @This();
        const Vector3 = vector3.Vector3(T);

        m: [4][4]T,

        pub const zero = Self{ .m = .{
            .{ 0, 0, 0, 0 },
            .{ 0, 0, 0, 0 },
            .{ 0, 0, 0, 0 },
            .{ 0, 0, 0, 0 },
        } };

        pub const identity = Self{ .m = .{
            .{ 1, 0, 0, 0 },
            .{ 0, 1, 0, 0 },
            .{ 0, 0, 1, 0 },
            .{ 0, 0, 0, 1 },
        } };

        pub fn translation(t: Vector3) Self {
            var result = identity;
            result.m[3][0] = t.x;
            result.m[3][1] = t.y;
            result.m[3][2] = t.z;
            return result;
        }

        pub fn scaling(s: Vector3) Self {
            var result = identity;
            result.m[0][0] = s.x;
            result.m[1][1] = s.y;
            result.m[2][2] = s.z;
            return result;
        }

        pub fn rotationX(angle: T) Self {
            const c = @cos(angle);
            const s = @sin(angle);
            var result = identity;
            result.m[1][1] = c;
            result.m[1][2] = s;
            result.m[2][1] = -s;
            result.m[2][2] = c;
            return result;
        }

        pub fn rotationY(angle: T) Self {
            const c = @cos(angle);
            const s = @sin(angle);
            var result = identity;
            result.m[0][0] = c;
            result.m[0][2] = -s;
            result.m[2][0] = s;
            result.m[2][2] = c;
            return result;
        }

        pub fn rotationZ(angle: T) Self {
            const c = @cos(angle);
            const s = @sin(angle);
            var result = identity;
            result.m[0][0] = c;
            result.m[0][1] = s;
            result.m[1][0] = -s;
            result.m[1][1] = c;
            return result;
        }

        pub fn rotation(axis: Vector3, angle: T) Self {
            const n = axis.normalize();
            const c = @cos(angle);
            const s = @sin(angle);
            const t = 1 - c;
            var result = identity;
            result.m[0][0] = t * n.x * n.x + c;
            result.m[0][1] = t * n.x * n.y + s * n.z;
            result.m[0][2] = t * n.x * n.z - s * n.y;
            result.m[1][0] = t * n.x * n.y - s * n.z;
            result.m[1][1] = t * n.y * n.y + c;
            result.m[1][2] = t * n.y * n.z + s * n.x;
            result.m[2][0] = t * n.x * n.z + s * n.y;
            result.m[2][1] = t * n.y * n.z - s * n.x;
            result.m[2][2] = t * n.z * n.z + c;
            return result;
        }

        pub fn mul(self: Self, other: Self) Self {
            var result = zero;
            for (0..4) |col| {
                for (0..4) |row| {
                    var sum: T = 0;
                    for (0..4) |k| {
                        sum += self.m[k][row] * other.m[col][k];
                    }
                    result.m[col][row] = sum;
                }
            }
            return result;
        }

        pub fn transpose(self: Self) Self {
            var result: Self = undefined;
            for (0..4) |col| {
                for (0..4) |row| {
                    result.m[col][row] = self.m[row][col];
                }
            }
            return result;
        }

        pub fn determinant(self: Self) T {
            const a = self.m;
            const b00 = a[0][0] * a[1][1] - a[0][1] * a[1][0];
            const b01 = a[0][0] * a[1][2] - a[0][2] * a[1][0];
            const b02 = a[0][0] * a[1][3] - a[0][3] * a[1][0];
            const b03 = a[0][1] * a[1][2] - a[0][2] * a[1][1];
            const b04 = a[0][1] * a[1][3] - a[0][3] * a[1][1];
            const b05 = a[0][2] * a[1][3] - a[0][3] * a[1][2];
            const b06 = a[2][0] * a[3][1] - a[2][1] * a[3][0];
            const b07 = a[2][0] * a[3][2] - a[2][2] * a[3][0];
            const b08 = a[2][0] * a[3][3] - a[2][3] * a[3][0];
            const b09 = a[2][1] * a[3][2] - a[2][2] * a[3][1];
            const b10 = a[2][1] * a[3][3] - a[2][3] * a[3][1];
            const b11 = a[2][2] * a[3][3] - a[2][3] * a[3][2];
            return b00 * b11 - b01 * b10 + b02 * b09 + b03 * b08 - b04 * b07 + b05 * b06;
        }

        /// Returns null when the matrix is singular.
        pub fn inverse(self: Self) ?Self {
            const a = self.m;
            const b00 = a[0][0] * a[1][1] - a[0][1] * a[1][0];
            const b01 = a[0][0] * a[1][2] - a[0][2] * a[1][0];
            const b02 = a[0][0] * a[1][3] - a[0][3] * a[1][0];
            const b03 = a[0][1] * a[1][2] - a[0][2] * a[1][1];
            const b04 = a[0][1] * a[1][3] - a[0][3] * a[1][1];
            const b05 = a[0][2] * a[1][3] - a[0][3] * a[1][2];
            const b06 = a[2][0] * a[3][1] - a[2][1] * a[3][0];
            const b07 = a[2][0] * a[3][2] - a[2][2] * a[3][0];
            const b08 = a[2][0] * a[3][3] - a[2][3] * a[3][0];
            const b09 = a[2][1] * a[3][2] - a[2][2] * a[3][1];
            const b10 = a[2][1] * a[3][3] - a[2][3] * a[3][1];
            const b11 = a[2][2] * a[3][3] - a[2][3] * a[3][2];

            const det = b00 * b11 - b01 * b10 + b02 * b09 + b03 * b08 - b04 * b07 + b05 * b06;
            if (det == 0) return null;
            const inv_det = 1.0 / det;

            return .{ .m = .{
                .{
                    (a[1][1] * b11 - a[1][2] * b10 + a[1][3] * b09) * inv_det,
                    (a[0][2] * b10 - a[0][1] * b11 - a[0][3] * b09) * inv_det,
                    (a[3][1] * b05 - a[3][2] * b04 + a[3][3] * b03) * inv_det,
                    (a[2][2] * b04 - a[2][1] * b05 - a[2][3] * b03) * inv_det,
                },
                .{
                    (a[1][2] * b08 - a[1][0] * b11 - a[1][3] * b07) * inv_det,
                    (a[0][0] * b11 - a[0][2] * b08 + a[0][3] * b07) * inv_det,
                    (a[3][2] * b02 - a[3][0] * b05 - a[3][3] * b01) * inv_det,
                    (a[2][0] * b05 - a[2][2] * b02 + a[2][3] * b01) * inv_det,
                },
                .{
                    (a[1][0] * b10 - a[1][1] * b08 + a[1][3] * b06) * inv_det,
                    (a[0][1] * b08 - a[0][0] * b10 - a[0][3] * b06) * inv_det,
                    (a[3][0] * b04 - a[3][1] * b02 + a[3][3] * b00) * inv_det,
                    (a[2][1] * b02 - a[2][0] * b04 - a[2][3] * b00) * inv_det,
                },
                .{
                    (a[1][1] * b07 - a[1][0] * b09 - a[1][2] * b06) * inv_det,
                    (a[0][0] * b09 - a[0][1] * b07 + a[0][2] * b06) * inv_det,
                    (a[3][1] * b01 - a[3][0] * b03 - a[3][2] * b00) * inv_det,
                    (a[2][0] * b03 - a[2][1] * b01 + a[2][2] * b00) * inv_det,
                },
            } };
        }

        pub fn eql(self: Self, other: Self) bool {
            for (self.m, other.m) |col_a, col_b| {
                for (col_a, col_b) |a, b| {
                    if (a != b) return false;
                }
            }
            return true;
        }

        pub fn approxEql(self: Self, other: Self, tolerance: T) bool {
            for (self.m, other.m) |col_a, col_b| {
                for (col_a, col_b) |a, b| {
                    if (@abs(a - b) > tolerance) return false;
                }
            }
            return true;
        }
    };
}

const pi = std.math.pi;
const Mat4 = Matrix4(f32);
const Vec3 = vector3.Vector3(f32);

test "identity is neutral" {
    const p = Vec3.init(1, -2, 3);
    try std.testing.expect(p.transformPoint(Mat4.identity).eql(p));
    try std.testing.expect(p.transformDirection(Mat4.identity).eql(p));
    const m = Mat4.translation(.init(4, 5, 6));
    try std.testing.expect(Mat4.identity.mul(m).eql(m));
    try std.testing.expect(m.mul(Mat4.identity).eql(m));
}

test "translation moves points but not directions" {
    const m = Mat4.translation(.init(1, 2, 3));
    try std.testing.expect(Vec3.init(1, 1, 1).transformPoint(m).eql(.init(2, 3, 4)));
    try std.testing.expect(Vec3.init(1, 1, 1).transformDirection(m).eql(.init(1, 1, 1)));
}

test "scaling scales points and directions" {
    const m = Mat4.scaling(.init(2, 3, 4));
    try std.testing.expect(Vec3.init(1, 1, 1).transformPoint(m).eql(.init(2, 3, 4)));
    try std.testing.expect(Vec3.init(1, -1, 0.5).transformDirection(m).eql(.init(2, -3, 2)));
}

test "axis rotations follow the right-hand rule" {
    try std.testing.expect(Vec3.unit_x.transformPoint(Mat4.rotationZ(pi / 2.0)).approxEql(Vec3.unit_y, 1e-6));
    try std.testing.expect(Vec3.unit_y.transformPoint(Mat4.rotationX(pi / 2.0)).approxEql(Vec3.unit_z, 1e-6));
    try std.testing.expect(Vec3.unit_z.transformPoint(Mat4.rotationY(pi / 2.0)).approxEql(Vec3.unit_x, 1e-6));
}

test "rotation around an arbitrary axis" {
    // Around z it matches rotationZ.
    const angle = 0.7;
    try std.testing.expect(Mat4.rotation(.init(0, 0, 2), angle).approxEql(Mat4.rotationZ(angle), 1e-6));

    // 120 degrees around the diagonal permutes the axes: x -> y.
    const m = Mat4.rotation(.init(1, 1, 1), 2.0 * pi / 3.0);
    try std.testing.expect(Vec3.unit_x.transformPoint(m).approxEql(Vec3.unit_y, 1e-6));

    // The axis itself is unchanged and lengths are preserved.
    const axis = Vec3.init(1, 1, 1).normalize();
    try std.testing.expect(axis.transformDirection(m).approxEql(axis, 1e-6));
    const v = Vec3.init(3, -1, 2).transformDirection(m);
    try std.testing.expectApproxEqAbs(Vec3.init(3, -1, 2).length(), v.length(), 1e-5);
}

test "mul composes right to left" {
    const rotate_then_translate = Mat4.translation(.init(10, 0, 0)).mul(Mat4.rotationZ(pi / 2.0));
    const p = Vec3.unit_x.transformPoint(rotate_then_translate);
    try std.testing.expect(p.approxEql(.init(10, 1, 0), 1e-6));
}

test "transpose" {
    const m = Mat4.translation(.init(1, 2, 3));
    const t = m.transpose();
    try std.testing.expectEqual(@as(f32, 1), t.m[0][3]);
    try std.testing.expectEqual(@as(f32, 2), t.m[1][3]);
    try std.testing.expectEqual(@as(f32, 3), t.m[2][3]);
    try std.testing.expect(t.transpose().eql(m));
}

test "determinant" {
    try std.testing.expectEqual(@as(f32, 1), Mat4.identity.determinant());
    try std.testing.expectEqual(@as(f32, 24), Mat4.scaling(.init(2, 3, 4)).determinant());
    try std.testing.expectEqual(@as(f32, 0), Mat4.scaling(.init(2, 3, 0)).determinant());
    try std.testing.expectApproxEqAbs(@as(f32, 1), Mat4.rotation(.init(1, -2, 3), 0.9).determinant(), 1e-5);
}

test "inverse undoes the transform" {
    try std.testing.expect(Mat4.identity.inverse().?.eql(Mat4.identity));

    const m = Mat4.translation(.init(1, 2, 3))
        .mul(Mat4.rotation(.init(1, 2, -1), 0.8))
        .mul(Mat4.scaling(.init(2, 0.5, 3)));
    const inv = m.inverse().?;
    try std.testing.expect(m.mul(inv).approxEql(Mat4.identity, 1e-5));
    try std.testing.expect(inv.mul(m).approxEql(Mat4.identity, 1e-5));

    const p = Vec3.init(4, -5, 6);
    try std.testing.expect(p.transformPoint(m).transformPoint(inv).approxEql(p, 1e-4));

    try std.testing.expectEqual(@as(?Mat4, null), Mat4.zero.inverse());
}

test "eql and approxEql" {
    const m = Mat4.translation(.init(1, 2, 3));
    try std.testing.expect(m.eql(Mat4.translation(.init(1, 2, 3))));
    try std.testing.expect(!m.eql(Mat4.identity));
    var n = m;
    n.m[3][0] += 0.0001;
    try std.testing.expect(!m.eql(n));
    try std.testing.expect(m.approxEql(n, 1e-3));
    try std.testing.expect(!m.approxEql(Mat4.identity, 1e-3));
}

test "generic scalar types" {
    const Mat4d = Matrix4(f64);
    const Vec3d = vector3.Vector3(f64);
    const m = Mat4d.translation(.init(1, 2, 3)).mul(Mat4d.scaling(.init(2, 2, 2)));
    try std.testing.expect(Vec3d.init(1, 1, 1).transformPoint(m).eql(.init(3, 4, 5)));
    try std.testing.expect(m.mul(m.inverse().?).approxEql(Mat4d.identity, 1e-12));
}
