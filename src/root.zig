const std = @import("std");
const Allocator = std.mem.Allocator;
const Io = std.Io;
const ArrayList = std.ArrayList;

const Vector3 = packed struct(u96) {x: f32, y: f32, z: f32};

const Triangle = packed struct(u400) {
    normal: Vector3,
    v1: Vector3,
    v2: Vector3,
    v3: Vector3,
    attribute: u16
};

pub fn load(io: Io, alloc: Allocator, input_path: []const u8) !void {
    const dir = Io.Dir.cwd();

    var file = try dir.openFile(io, input_path, .{});
    defer file.close(io);

    var buffer: [1024*128]u8 = undefined;
    var reader = file.reader(io, &buffer);
    const w: *Io.Reader = &reader.interface;

    // skip the header
    _ = try w.discard(.limited(80));

    const num_triangles = try w.takeInt(u32, .little);

    var triangles: ArrayList(Triangle) = try .initCapacity(alloc, num_triangles);

    for (0..num_triangles) |_| {
        const tb = try w.take(50);
        const tri: Triangle = @bitCast(tb[0..50].*);

        try triangles.append(alloc, tri);
    }

    std.debug.print("Read {}\n", .{triangles.items.len});
}
