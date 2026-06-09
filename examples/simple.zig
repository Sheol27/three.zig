const std = @import("std");
const math = std.math;
const Io = std.Io;
const path = std.fs.path;

const three = @import("three");
const Mesh = three.Mesh;

pub fn main(init: std.process.Init) !void {
    const allocator = init.arena.allocator();
    const args = try init.minimal.args.toSlice(allocator);

    if (args.len != 2) {
        std.process.fatal("Missing input file", .{});
    }

    const input_path: []const u8 = args[1];

    const mesh: Mesh = try .fromFile(init.io, allocator, input_path);
    defer mesh.deinit(allocator);

    std.debug.print("Loaded {} faces with {} vertices and {} indices\n", .{ mesh.triangles_count, mesh.indices.len, mesh.vertices.len });

    const bb = mesh.computeBoundingBox();
    std.debug.print("{any}\n", .{bb});
    std.debug.print("{any}\n", .{bb.center()});
}
