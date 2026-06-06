const std = @import("std");
const Allocator = std.mem.Allocator;
const Io = std.Io;
const ArrayList = std.ArrayList;

const Vector3 = extern struct {x: f32, y: f32, z: f32};

const Mesh = struct {
    vertices: []Vector3,
    indices: []usize,
    normals: []Vector3,
};

pub fn load(io: Io, alloc: Allocator, input_path: []const u8) !Mesh {
    const dir = Io.Dir.cwd();

    var file = try dir.openFile(io, input_path, .{});
    defer file.close(io);

    var buffer: [1024*128]u8 = undefined;
    var reader = file.reader(io, &buffer);
    const w: *Io.Reader = &reader.interface;

    // skip the header
    _ = try w.discard(.limited(80));

    const num_triangles = try w.takeInt(u32, .little);

    var vertices: ArrayList(Vector3) = try .initCapacity(alloc, num_triangles * 3);
    defer vertices.deinit(alloc);

    var normals: ArrayList(Vector3) = try .initCapacity(alloc, num_triangles);
    defer normals.deinit(alloc);

    var indices: ArrayList(usize) = try .initCapacity(alloc, num_triangles * 3);
    defer indices.deinit(alloc);

    var hm: std.AutoHashMap([12]u8, usize) = .init(alloc);
    defer hm.deinit();
    try hm.ensureTotalCapacity(num_triangles * 3);

    for (0..num_triangles) |_| {
        const nb: [12]u8 = (try w.takeArray(12)).*;
        const normal: Vector3 = @bitCast(nb);

        for (0..3) |_| {
            const vb: [12]u8 = (try w.takeArray(12)).*;
            const gop = try hm.getOrPut(vb);
            if (!gop.found_existing) {
                gop.value_ptr.* = vertices.items.len;
                try vertices.append(alloc, @bitCast(vb));
            }
            try indices.append(alloc, gop.value_ptr.*);
        }

        // skip attribute
        _ = try w.discard(.limited(2));
        try normals.append(alloc, normal);
    }

    std.debug.print("Read {} vertices {} indices and {} normals\n",
        .{vertices.items.len, indices.items.len, normals.items.len,});

    return Mesh {
        .vertices = try vertices.toOwnedSlice(alloc),
        .indices = try indices.toOwnedSlice(alloc),
        .normals = try normals.toOwnedSlice(alloc)
    };
}
