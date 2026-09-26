const std = @import("std");
const grid = @import("grid.zig");

pub fn main() !void {
    var buffer: [1024]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buffer);
    const allocator = fba.allocator();

    var board = try grid.init(allocator, 5, 5);
    defer grid.deinit(&board, allocator);

    board.set(1, 2, 1);
    board.set(2, 2, 1);
    board.set(3, 2, 1);

    var i: u8 = 0;
    while (i < 5) : (i += 1) {
        grid.draw(board);
        grid.evolve(&board);
    }
}
