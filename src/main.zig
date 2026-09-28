const std = @import("std");
const grid = @import("grid.zig");
const window = @import("window.zig");

//ansi escape codes
const esc = "\x1B";
const csi = esc ++ "[";

const cursor_show = csi ++ "?25h"; //h=high
const cursor_hide = csi ++ "?25l"; //l=low
const cursor_home = csi ++ "1;1H"; //1,1

const color_fg = "38;5;";
const color_bg = "48;5;";
const color_fg_def = csi ++ color_fg ++ "15m"; // white
const color_bg_def = csi ++ color_bg ++ "0m"; // black
const color_def = color_bg_def ++ color_fg_def;

const screen_clear = csi ++ "2J";
const screen_buf_on = csi ++ "?1049h"; //h=high
const screen_buf_off = csi ++ "?1049l"; //l=low

const nl = "\n";

const term_on = screen_buf_on ++ cursor_hide ++ cursor_home ++ screen_clear ++ color_def;
const term_off = screen_buf_off ++ cursor_show ++ nl;

pub fn main(init: std.process.Init) !void {

    const io = init.io;
    const args = try init.minimal.args.toSlice(init.arena.allocator());

    if (args.len != 2) { return error.OnlyOneArgAllowed; }

    const allocator = std.heap.page_allocator;
    // var buffer: [256 * 1024]u8 = undefined;
    // var fba = std.heap.FixedBufferAllocator.init(&buffer);
    // const allocator = fba.allocator();

    var board = try grid.init(allocator, 1000, 2000);
    defer grid.deinit(&board, allocator);

    {
        const fileContents = try getFileContents(io, allocator, args[1]);
        defer allocator.free(fileContents);

        try grid.starting_pattern(&board, fileContents, 331, 625);
    }

    try window.run(io, &board);
}

fn getFileContents(io: std.Io, allocator: std.mem.Allocator, path: []const u8) ![]u8 {
    const contents = try std.Io.Dir.readFileAlloc(
        std.Io.Dir.cwd(), io, path, allocator, .limited(256 * 1024));

    return contents;
}
