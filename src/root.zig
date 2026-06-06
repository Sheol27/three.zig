const std = @import("std");
const Allocator = std.mem.Allocator;
const Io = std.Io;
const ArrayList = std.ArrayList;

const Vector3 = extern struct {x: f32, y: f32, z: f32};

pub const Mesh = struct {
    vertices: []Vector3,
    indices: []usize,
    normals: []Vector3,
    triangles_count: usize,

    /// Parse a binary STL from any reader. Caller owns the result; call deinit.
    pub fn fromReader(r: *Io.Reader, alloc: Allocator) !Mesh {
        // skip header
        _ = try r.discard(.limited(80));
        const triangles_count: usize = try r.takeInt(u32, .little);

        var vertices: ArrayList(Vector3) = try .initCapacity(alloc, triangles_count * 3);
        errdefer vertices.deinit(alloc);
        var normals: ArrayList(Vector3) = try .initCapacity(alloc, triangles_count);
        errdefer normals.deinit(alloc);
        var indices: ArrayList(usize) = try .initCapacity(alloc, triangles_count * 3);
        errdefer indices.deinit(alloc);

        var hm: std.AutoHashMap([12]u8, usize) = .init(alloc);
        defer hm.deinit();
        try hm.ensureTotalCapacity(@intCast(triangles_count * 3));

        for (0..triangles_count) |_| {
            const nb: [12]u8 = (try r.takeArray(12)).*;
            const normal: Vector3 = @bitCast(nb);
            for (0..3) |_| {
                const vb: [12]u8 = (try r.takeArray(12)).*;
                const gop = hm.getOrPutAssumeCapacity(vb);
                if (!gop.found_existing) {
                    gop.value_ptr.* = vertices.items.len;
                    vertices.appendAssumeCapacity(@bitCast(vb));
                }
                indices.appendAssumeCapacity(gop.value_ptr.*);
            }
            // skip attribute bytes
            _ = try r.discard(.limited(2));
            normals.appendAssumeCapacity(normal);
        }

        const verts = try vertices.toOwnedSlice(alloc);
        errdefer alloc.free(verts);
        const inds = try indices.toOwnedSlice(alloc);
        errdefer alloc.free(inds);
        const norms = try normals.toOwnedSlice(alloc);

        return .{ .vertices = verts, .indices = inds, .normals = norms, .triangles_count = triangles_count};
    }

    /// Convenience: open a file by path and parse it.
    pub fn fromFile(io: Io, alloc: Allocator, path: []const u8) !Mesh {
        const dir = Io.Dir.cwd();
        var file = try dir.openFile(io, path, .{});
        defer file.close(io);
        var buffer: [1024 * 128]u8 = undefined;
        var reader = file.reader(io, &buffer);
        return fromReader(&reader.interface, alloc);
    }

    pub fn deinit(self: *const Mesh, alloc: Allocator) void {
        alloc.free(self.vertices);
        alloc.free(self.indices);
        alloc.free(self.normals);
    }
};
