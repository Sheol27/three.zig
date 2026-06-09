const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const mod = b.addModule("three", .{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
    });

    const exe = b.addExecutable(.{
        .name = "viewer",
        .root_module = b.createModule(.{
            .root_source_file = b.path("examples/simple.zig"),
            .optimize = optimize,
            .target = target,
            .strip = optimize != .Debug,
            .single_threaded = true,
            .imports = &.{
                .{ .name = "three", .module = mod },
            },
        }),
    });

    b.installArtifact(exe);

    const run_exe = b.addRunArtifact(exe);

    const run_step = b.step("run", "Run the example");

    if (b.args) |args| {
        run_exe.addArgs(args);
    }

    run_step.dependOn(&run_exe.step);

    const mod_tests = b.addTest(.{ .root_module = mod });
    const run_mod_tests = b.addRunArtifact(mod_tests);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_mod_tests.step);
}
