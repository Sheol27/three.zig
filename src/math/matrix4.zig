const std = @import("std");
const Vector3 = @import("vector3.zig").Vector3;

pub const Matrix4 = extern struct {
    m: [4][4]f32,

    pub const zero = Matrix4{ .m = .{
        .{ 0, 0, 0, 0 },
        .{ 0, 0, 0, 0 },
        .{ 0, 0, 0, 0 },
        .{ 0, 0, 0, 0 },
    } };

    pub const identity = Matrix4{ .m = .{
        .{ 1, 0, 0, 0 },
        .{ 0, 1, 0, 0 },
        .{ 0, 0, 1, 0 },
        .{ 0, 0, 0, 1 },
    } };

    pub fn translation(t: Vector3) Matrix4 {
        var result = identity;
        result.m[3][0] = t.x;
        result.m[3][1] = t.y;
        result.m[3][2] = t.z;
        return result;
    }

    pub fn scaling(s: Vector3) Matrix4 {
        var result = identity;
        result.m[0][0] = s.x;
        result.m[1][1] = s.y;
        result.m[2][2] = s.z;
        return result;
    }

    pub fn rotationX(angle: f32) Matrix4 {
        const c = @cos(angle);
        const s = @sin(angle);
        var result = identity;
        result.m[1][1] = c;
        result.m[1][2] = s;
        result.m[2][1] = -s;
        result.m[2][2] = c;
        return result;
    }

    pub fn rotationY(angle: f32) Matrix4 {
        const c = @cos(angle);
        const s = @sin(angle);
        var result = identity;
        result.m[0][0] = c;
        result.m[0][2] = -s;
        result.m[2][0] = s;
        result.m[2][2] = c;
        return result;
    }

    pub fn rotationZ(angle: f32) Matrix4 {
        const c = @cos(angle);
        const s = @sin(angle);
        var result = identity;
        result.m[0][0] = c;
        result.m[0][1] = s;
        result.m[1][0] = -s;
        result.m[1][1] = c;
        return result;
    }

    pub fn rotation(axis: Vector3, angle: f32) Matrix4 {
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

    pub fn mul(self: Matrix4, other: Matrix4) Matrix4 {
        var result = zero;
        for (0..4) |col| {
            for (0..4) |row| {
                var sum: f32 = 0;
                for (0..4) |k| {
                    sum += self.m[k][row] * other.m[col][k];
                }
                result.m[col][row] = sum;
            }
        }
        return result;
    }

    pub fn transpose(self: Matrix4) Matrix4 {
        var result: Matrix4 = undefined;
        for (0..4) |col| {
            for (0..4) |row| {
                result.m[col][row] = self.m[row][col];
            }
        }
        return result;
    }

    pub fn determinant(self: Matrix4) f32 {
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
    pub fn inverse(self: Matrix4) ?Matrix4 {
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

    pub fn eql(self: Matrix4, other: Matrix4) bool {
        for (self.m, other.m) |col_a, col_b| {
            for (col_a, col_b) |a, b| {
                if (a != b) return false;
            }
        }
        return true;
    }

    pub fn approxEql(self: Matrix4, other: Matrix4, tolerance: f32) bool {
        for (self.m, other.m) |col_a, col_b| {
            for (col_a, col_b) |a, b| {
                if (@abs(a - b) > tolerance) return false;
            }
        }
        return true;
    }
};

const pi = std.math.pi;

test "identity is neutral" {
    const p = Vector3.init(1, -2, 3);
    try std.testing.expect(p.transformPoint(Matrix4.identity).eql(p));
    try std.testing.expect(p.transformDirection(Matrix4.identity).eql(p));
    const m = Matrix4.translation(.init(4, 5, 6));
    try std.testing.expect(Matrix4.identity.mul(m).eql(m));
    try std.testing.expect(m.mul(Matrix4.identity).eql(m));
}

test "translation moves points but not directions" {
    const m = Matrix4.translation(.init(1, 2, 3));
    try std.testing.expect(Vector3.init(1, 1, 1).transformPoint(m).eql(.init(2, 3, 4)));
    try std.testing.expect(Vector3.init(1, 1, 1).transformDirection(m).eql(.init(1, 1, 1)));
}

test "scaling scales points and directions" {
    const m = Matrix4.scaling(.init(2, 3, 4));
    try std.testing.expect(Vector3.init(1, 1, 1).transformPoint(m).eql(.init(2, 3, 4)));
    try std.testing.expect(Vector3.init(1, -1, 0.5).transformDirection(m).eql(.init(2, -3, 2)));
}

test "axis rotations follow the right-hand rule" {
    try std.testing.expect(Vector3.unit_x.transformPoint(Matrix4.rotationZ(pi / 2.0)).approxEql(Vector3.unit_y, 1e-6));
    try std.testing.expect(Vector3.unit_y.transformPoint(Matrix4.rotationX(pi / 2.0)).approxEql(Vector3.unit_z, 1e-6));
    try std.testing.expect(Vector3.unit_z.transformPoint(Matrix4.rotationY(pi / 2.0)).approxEql(Vector3.unit_x, 1e-6));
}

test "rotation around an arbitrary axis" {
    // Around z it matches rotationZ.
    const angle = 0.7;
    try std.testing.expect(Matrix4.rotation(.init(0, 0, 2), angle).approxEql(Matrix4.rotationZ(angle), 1e-6));

    // 120 degrees around the diagonal permutes the axes: x -> y.
    const m = Matrix4.rotation(.init(1, 1, 1), 2.0 * pi / 3.0);
    try std.testing.expect(Vector3.unit_x.transformPoint(m).approxEql(Vector3.unit_y, 1e-6));

    // The axis itself is unchanged and lengths are preserved.
    const axis = Vector3.init(1, 1, 1).normalize();
    try std.testing.expect(axis.transformDirection(m).approxEql(axis, 1e-6));
    const v = Vector3.init(3, -1, 2).transformDirection(m);
    try std.testing.expectApproxEqAbs(Vector3.init(3, -1, 2).length(), v.length(), 1e-5);
}

test "mul composes right to left" {
    const rotate_then_translate = Matrix4.translation(.init(10, 0, 0)).mul(Matrix4.rotationZ(pi / 2.0));
    const p = Vector3.unit_x.transformPoint(rotate_then_translate);
    try std.testing.expect(p.approxEql(.init(10, 1, 0), 1e-6));
}

test "transpose" {
    const m = Matrix4.translation(.init(1, 2, 3));
    const t = m.transpose();
    try std.testing.expectEqual(@as(f32, 1), t.m[0][3]);
    try std.testing.expectEqual(@as(f32, 2), t.m[1][3]);
    try std.testing.expectEqual(@as(f32, 3), t.m[2][3]);
    try std.testing.expect(t.transpose().eql(m));
}

test "determinant" {
    try std.testing.expectEqual(@as(f32, 1), Matrix4.identity.determinant());
    try std.testing.expectEqual(@as(f32, 24), Matrix4.scaling(.init(2, 3, 4)).determinant());
    try std.testing.expectEqual(@as(f32, 0), Matrix4.scaling(.init(2, 3, 0)).determinant());
    try std.testing.expectApproxEqAbs(@as(f32, 1), Matrix4.rotation(.init(1, -2, 3), 0.9).determinant(), 1e-5);
}

test "inverse undoes the transform" {
    try std.testing.expect(Matrix4.identity.inverse().?.eql(Matrix4.identity));

    const m = Matrix4.translation(.init(1, 2, 3))
        .mul(Matrix4.rotation(.init(1, 2, -1), 0.8))
        .mul(Matrix4.scaling(.init(2, 0.5, 3)));
    const inv = m.inverse().?;
    try std.testing.expect(m.mul(inv).approxEql(Matrix4.identity, 1e-5));
    try std.testing.expect(inv.mul(m).approxEql(Matrix4.identity, 1e-5));

    const p = Vector3.init(4, -5, 6);
    try std.testing.expect(p.transformPoint(m).transformPoint(inv).approxEql(p, 1e-4));

    try std.testing.expectEqual(@as(?Matrix4, null), Matrix4.zero.inverse());
}

test "eql and approxEql" {
    const m = Matrix4.translation(.init(1, 2, 3));
    try std.testing.expect(m.eql(Matrix4.translation(.init(1, 2, 3))));
    try std.testing.expect(!m.eql(Matrix4.identity));
    var n = m;
    n.m[3][0] += 0.0001;
    try std.testing.expect(!m.eql(n));
    try std.testing.expect(m.approxEql(n, 1e-3));
    try std.testing.expect(!m.approxEql(Matrix4.identity, 1e-3));
}
