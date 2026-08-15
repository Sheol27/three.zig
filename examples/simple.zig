const std = @import("std");
const print = std.debug.print;
const three = @import("three");

pub fn main(init: std.process.Init) !void {
    const allocator = init.arena.allocator();
    const args = try init.minimal.args.toSlice(allocator);

    if (args.len != 2) {
        std.process.fatal("Missing input file", .{});
    }

    const input_path: []const u8 = args[1];

    const options = three.formats.ReadOptions.fromPath(input_path) orelse
        std.process.fatal("Unknown format: {s}", .{input_path});

    const mesh: three.Mesh = try three.formats.load(init.io, allocator, input_path, options);
    defer mesh.deinit(allocator);

    print("Loaded {} faces with {} vertices and {} indices\n", .{ mesh.triangles_count, mesh.vertices.len, mesh.indices.len });

    const bb = mesh.computeBoundingBox();
    print("{any}\n", .{bb});
    print("{any}\n", .{bb.center()});
}
