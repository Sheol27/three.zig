const std = @import("std");
const math = std.math;
const Io = std.Io;
const path = std.fs.path;
const ArrayList = std.ArrayList;

const ztloader = @import("ztloader");

const Vector3 = packed struct(u96) {x: f32, y: f32, z: f32};

const Triangle = packed struct(u400) {
    normal: Vector3,
    v1: Vector3,
    v2: Vector3,
    v3: Vector3,
    attribute: u16
};

pub fn main(init: std.process.Init) !void {
    const allocator = init.arena.allocator();
    const args = try init.minimal.args.toSlice(allocator);

    if (args.len != 2) {
        std.process.fatal("Missing input file", .{});
    }

    const input_file: []const u8 = args[1];

    const dir = Io.Dir.cwd();

    var file = try dir.openFile(init.io, input_file, .{});
    defer file.close(init.io);

    // std.debug.print("Opening {s}\n", .{input_file});

    var buffer: [1024*128]u8 = undefined;
    var reader = file.reader(init.io, &buffer);
    const w: *Io.Reader = &reader.interface;

    _ = try w.take(80);

    // std.debug.print("Header => {s}\n", .{header});

    const num_triangles = try w.takeInt(u32, .little);
    // std.debug.print("Triangles: {}\n", .{num_triangles});

    var min: Vector3 = .{.x = math.floatMax(f32), .y = math.floatMax(f32), .z = math.floatMax(f32)};
    var max: Vector3 = .{.x = math.floatMin(f32), .y = math.floatMin(f32), .z = math.floatMin(f32)};

    for (0..num_triangles) |_| {
        const tb = try w.take(50);
        const tri: Triangle = @bitCast(tb[0..50].*);

        if (min.x > tri.v1.x) min.x = tri.v1.x;
        if (max.x < tri.v1.x) max.x = tri.v1.x;
        if (min.y > tri.v1.y) min.y = tri.v1.y;
        if (max.y < tri.v1.y) max.y = tri.v1.y;
        if (min.z > tri.v1.z) min.z = tri.v1.z;
        if (max.z < tri.v1.z) max.z = tri.v1.z;

        if (min.x > tri.v2.x) min.x = tri.v2.x;
        if (max.x < tri.v2.x) max.x = tri.v2.x;
        if (min.y > tri.v2.y) min.y = tri.v2.y;
        if (max.y < tri.v2.y) max.y = tri.v2.y;
        if (min.z > tri.v2.z) min.z = tri.v2.z;
        if (max.z < tri.v2.z) max.z = tri.v2.z;

        if (min.x > tri.v3.x) min.x = tri.v3.x;
        if (max.x < tri.v3.x) max.x = tri.v3.x;
        if (min.y > tri.v3.y) min.y = tri.v3.y;
        if (max.y < tri.v3.y) max.y = tri.v3.y;
        if (min.z > tri.v3.z) min.z = tri.v3.z;
        if (max.z < tri.v3.z) max.z = tri.v3.z;
        // try triangles.append(allocator, tri);
    }


    // std.debug.print("MIN: {} MAX: {}\n", .{min, max});


    // ztloader.load();
}
