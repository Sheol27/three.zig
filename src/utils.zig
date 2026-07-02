const math = @import("math.zig");
const Vector3 = math.Vector3;

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
