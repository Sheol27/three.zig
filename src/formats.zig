const std = @import("std");
const Io = std.Io;
const Allocator = std.mem.Allocator;

const Mesh = @import("Mesh.zig");

pub const Stl = @import("formats/Stl.zig");

pub const Format = enum {
    stl,

    pub fn fromPath(path: []const u8) ?Format {
        const ext = std.fs.path.extension(path);
        if (std.ascii.eqlIgnoreCase(ext, ".stl")) return .stl;
        return null;
    }
};

pub const ReadOptions = union(Format) {
    stl: Stl.ReadOptions,

    pub fn fromPath(path: []const u8) ?ReadOptions {
        return switch (Format.fromPath(path) orelse return null) {
            .stl => .{ .stl = .{} },
        };
    }
};

pub const WriteOptions = union(Format) {
    stl: Stl.WriteOptions,

    pub fn fromPath(path: []const u8) ?WriteOptions {
        return switch (Format.fromPath(path) orelse return null) {
            .stl => .{ .stl = .{} },
        };
    }
};

/// Parse a mesh from any reader, in the format given by the options.
pub fn loadFromReader(r: *Io.Reader, alloc: Allocator, options: ReadOptions) !Mesh {
    return switch (options) {
        .stl => Stl.loadFromReader(r, alloc),
    };
}

/// Open the file and parse it. Use `ReadOptions.fromPath` to infer the format
/// from the extension.
pub fn load(io: Io, alloc: Allocator, path: []const u8, options: ReadOptions) !Mesh {
    var file = try Io.Dir.cwd().openFile(io, path, .{});
    defer file.close(io);

    var buffer: [1024 * 128]u8 = undefined;
    var reader = file.reader(io, &buffer);
    return loadFromReader(&reader.interface, alloc, options);
}

/// Write the mesh to any writer.
pub fn saveToWriter(mesh: *const Mesh, w: *Io.Writer, options: WriteOptions) !void {
    return switch (options) {
        .stl => |stl_options| Stl.saveToWriter(mesh, w, stl_options),
    };
}

/// Create the file and write the mesh to it.
pub fn save(mesh: *const Mesh, io: Io, path: []const u8, options: WriteOptions) !void {
    var file = try Io.Dir.cwd().createFile(io, path, .{});
    defer file.close(io);

    var buffer: [1024 * 128]u8 = undefined;
    var writer = file.writer(io, &buffer);
    try saveToWriter(mesh, &writer.interface, options);
    try writer.interface.flush();
}

test "Format.fromPath infers the format from the extension" {
    try std.testing.expectEqual(@as(?Format, .stl), Format.fromPath("model.stl"));
    try std.testing.expectEqual(@as(?Format, .stl), Format.fromPath("dir/MODEL.STL"));
    try std.testing.expectEqual(@as(?Format, null), Format.fromPath("model.obj"));
    try std.testing.expectEqual(@as(?Format, null), Format.fromPath("model"));
}

test "saveToWriter output round-trips through loadFromReader" {
    const primitives = @import("primitives.zig");
    const alloc = std.testing.allocator;
    const cube = try primitives.cube(alloc, 2);
    defer cube.deinit(alloc);

    var buf: [8192]u8 = undefined;
    var w: Io.Writer = .fixed(&buf);
    try saveToWriter(&cube, &w, .{ .stl = .{ .encoding = .ascii } });

    var r: Io.Reader = .fixed(w.buffered());
    const parsed = try loadFromReader(&r, alloc, .{ .stl = .{} });
    defer parsed.deinit(alloc);

    try std.testing.expectEqual(cube.triangles_count, parsed.triangles_count);
    try std.testing.expectEqualSlices(usize, cube.indices, parsed.indices);
}
