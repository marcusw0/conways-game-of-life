const std = @import("std");
const grid = @import("grid.zig");
const window = @import("window.zig");

pub fn main(init: std.process.Init) !void {

    const io = init.io;
    const args = try init.minimal.args.toSlice(init.arena.allocator());

    if (args.len != 2) { return error.OnlyOneArgAllowed; }

    var buffer: [514 * 1024]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buffer);
    const allocator = fba.allocator();

    var board = try grid.init(allocator, 2048, 1024);
    defer grid.deinit(&board, allocator);

    const file_allocator = std.heap.page_allocator;
    {
        const fileContents = try getFileContents(io, file_allocator, args[1]);
        defer file_allocator.free(fileContents);

        try grid.starting_pattern(&board, fileContents, 331, 625);
    }

    try window.run(io, &board);
}

fn getFileContents(io: std.Io, allocator: std.mem.Allocator, path: []const u8) ![]u8 {
    const contents = try std.Io.Dir.readFileAlloc(
        std.Io.Dir.cwd(), io, path, allocator, .limited(256 * 1024));

    return contents;
}
