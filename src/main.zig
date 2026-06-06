const std = @import("std");
const math = std.math;
const Io = std.Io;
const path = std.fs.path;

const ztloader = @import("ztloader");
const Mesh = ztloader.Mesh;

pub fn main(init: std.process.Init) !void {
    const allocator = init.arena.allocator();
    const args = try init.minimal.args.toSlice(allocator);

    if (args.len != 2) {
        std.process.fatal("Missing input file", .{});
    }

    const input_path: []const u8 = args[1];

    const mesh: Mesh = try .fromFile(init.io, allocator, input_path);
    defer mesh.deinit(allocator);

    std.debug.print("Loaded {} faces\n", .{mesh.triangles_count});
}
