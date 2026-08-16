const std = @import("std");
const math = @import("math.zig");
const Vector3 = math.Vector3(f32);

pub fn triangleNormal(a: Vector3, b: Vector3, c: Vector3) Vector3 {
    const u = b.sub(a);
    const v = c.sub(a);

    var n = u.cross(v);

    const len = n.length();

    if (len > 0) {
        n = n.divScalar(len);
    }

    return n;
}

pub const le = struct {
    pub fn f32Bytes(v: f32) [4]u8 {
        var b: [4]u8 = undefined;
        std.mem.writeInt(u32, &b, @bitCast(v), .little);
        return b;
    }
    pub fn u32Bytes(v: u32) [4]u8 {
        var b: [4]u8 = undefined;
        std.mem.writeInt(u32, &b, v, .little);
        return b;
    }
};
