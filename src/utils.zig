const math = @import("math.zig");
const Vector3 = math.Vector3;

pub fn triangleNormal(a: Vector3, b: Vector3, c: Vector3) Vector3 {
    const ux = b.x - a.x;
    const uy = b.y - a.y;
    const uz = b.z - a.z;
    const vx = c.x - a.x;
    const vy = c.y - a.y;
    const vz = c.z - a.z;
    var nx = uy * vz - uz * vy;
    var ny = uz * vx - ux * vz;
    var nz = ux * vy - uy * vx;
    const len = @sqrt(nx * nx + ny * ny + nz * nz);
    if (len > 0) {
        nx /= len;
        ny /= len;
        nz /= len;
    }
    return .init(nx, ny, nz);
}
