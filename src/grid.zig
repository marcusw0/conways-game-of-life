const std = @import("std");

// if x = 70, y = 12
//const word_idx = x / 64; // which word contains it
//const bit_idx: u6 = @intCast(x % 64); // where inside the word
// Cell(70, 12) => grid[12][1], bit 6

//const mask = @as(u64, 1) << bit_idx;
//grid[y][word_idx] |= mask;

pub const Grid = struct {
    rows: usize,
    cols: usize,
    words_per_row: usize,
    data: []u64,
    next_data: []u64,

    pub fn get(self: Grid, col: usize, row: usize) u1 {
        std.debug.assert(col < self.cols and row < self.rows);

        const word_idx = row * self.words_per_row + (col / 64);
        const bit_idx: u6 = @intCast(col % 64);

        const word = self.data[word_idx];
        const mask = @as(u64, 1) << bit_idx;

        if (word & mask == 0) {
            return 0;
        } else {
            return 1;
        }
    }

    pub fn set(self: *Grid, col: usize, row: usize, value: u1) void {
        std.debug.assert(col < self.cols and row < self.rows);

        const word_idx = row * self.words_per_row + (col / 64);
        const bit_idx: u6 = @intCast(col % 64);

        // u8, bit_idx 3 => 00001000
        const mask = @as(u64, 1) << bit_idx;

        // what to write
        const new_value = @as(u64, value) << bit_idx;

        const word = self.data[word_idx];

        // word            00101100
        // ~mask           11110111
        // word & ~mask    00100100
        // new_value       00000000
        // (&) | new_value 00100100
        self.data[word_idx] = (word & ~mask) | new_value;
    }

    pub fn setNext(self: *Grid, col: usize, row: usize, value: u1) void {
        std.debug.assert(col < self.cols and row < self.rows);

        const word_idx = row * self.words_per_row + (col / 64);
        const bit_idx: u6 = @intCast(col % 64);

        // u8, bit_idx 3 => 00001000
        const mask = @as(u64, 1) << bit_idx;

        // what to write
        const new_value = @as(u64, value) << bit_idx;

        const word = self.next_data[word_idx];

        // word            00101100
        // ~mask           11110111
        // word & ~mask    00100100
        // new_value       00000000
        // (&) | new_value 00100100
        self.next_data[word_idx] = (word & ~mask) | new_value;
    }
};

pub fn init(allocator: std.mem.Allocator, cols: usize, rows: usize) !Grid {
    const wpr = (cols + 63) / 64;
    const word_count = rows * wpr;

    const data_buffer = try allocator.alloc(u64, word_count);
    errdefer allocator.free(data_buffer);

    const next_buffer = try allocator.alloc(u64, word_count);

    @memset(data_buffer, 0);
    @memset(next_buffer, 0);

    return Grid{
        .rows = rows,
        .cols = cols,
        .words_per_row = wpr,
        .data = data_buffer,
        .next_data = next_buffer,
    };
}

pub fn deinit(self: *Grid, allocator: std.mem.Allocator) void {
    allocator.free(self.data);
    allocator.free(self.next_data);
    self.* = undefined;
}

pub fn draw(self: Grid, writer: *std.Io.Writer) !void {
    for (0..self.rows) |row| {
        for (0..self.cols) |col| {
            if (self.get(col, row) == 1) {
                try writer.print("*", .{});
            } else {
                try writer.print(" ", .{});
            }
        }
        try writer.print("\n", .{});
    }
}

pub fn evolve(self: *Grid) void {
    var i: usize = 0;

    while (i < self.rows) : (i += 1) {
        var j: usize = 0;
        const row_above = (i + self.rows - 1) % self.rows;
        const row_below = (i + 1) % self.rows;

        while (j < self.cols) : (j += 1) {
            const col_left = (j + self.cols - 1) % self.cols;
            const col_right = (j + 1) % self.cols;

            var num_neighbors: u4 = 0;
            num_neighbors += self.get(col_left, row_above);
            num_neighbors += self.get(j, row_above);
            num_neighbors += self.get(col_right, row_above);
            num_neighbors += self.get(col_left, i);
            num_neighbors += self.get(col_right, i);
            num_neighbors += self.get(col_left, row_below);
            num_neighbors += self.get(j, row_below);
            num_neighbors += self.get(col_right, row_below);

            var new_state: u1 = 0;
            if (num_neighbors == 3 or (self.get(j, i) == 1 and num_neighbors == 2)) {
                new_state = 1;
            }

            self.setNext(j, i, new_state);
        }
    }

    const old_data = self.data;
    self.data = self.next_data;
    self.next_data = old_data;
}

pub fn starting_pattern(self: *Grid, pattern: []const u8, start_row: usize, start_col: usize) !void {
    var iter = std.mem.splitScalar(u8, pattern, '\n');
    var row_index: usize = 0;

    while (iter.next()) |row| : (row_index += 1) {
        if (row.len == 0 and iter.peek() == null) {
            break;
        }
        if (row.len > self.cols) { return error.MismatchedSize; }
        if (row_index >= self.rows) { return error.MismatchedSize; }
        for (row, 0..) |value, col_index| {
            switch (value) {
                '.' => self.set(start_col + col_index, start_row + row_index, 0),
                '*' => self.set(start_col + col_index, start_row + row_index, 1),
                else => return error.UnkownCharacter,
            }
        }
    }
}

pub fn randomSeed(grid: *Grid, gen: *std.Random.DefaultPrng) void {
    const rand = gen.random();
    var i: usize = 0;

    while (i < grid.rows) : (i += 1) {
        var j: usize = 0;
        while (j < grid.cols) : (j += 1) {
            grid.set(j, i, rand.intRangeAtMost(u1, 0, 1));
        }
    }
}

test "new grid check dead cells" {
    const allocator = std.testing.allocator;

    var grid = try init(allocator, 8, 8);
    defer deinit(&grid, allocator);

    for (grid.data, grid.next_data) |current, next| {
        try std.testing.expectEqual(@as(u8, 0), current);
        try std.testing.expectEqual(@as(u8, 0), next);
    }
}

test "get and set" {
    const allocator = std.testing.allocator;

    var grid = try init(allocator, 8, 8);
    defer deinit(&grid, allocator);

    grid.set(7, 7, 1);

    const got = grid.get(7, 7);
    const before = grid.get(6, 7);
    const after = grid.get(7, 6);

    try std.testing.expect(got == 1);
    try std.testing.expect(before == 0);
    try std.testing.expect(after == 0);
}

test "test evolve blinker" {
    const allocator = std.testing.allocator;

    var grid = try init(allocator, 5, 5);
    defer deinit(&grid, allocator);

    grid.set(1, 2, 1);
    grid.set(2, 2, 1);
    grid.set(3, 2, 1);

    evolve(&grid);

    try std.testing.expectEqual(@as(u8, 1), grid.get(2, 1));
    try std.testing.expectEqual(@as(u8, 1), grid.get(2, 2));
    try std.testing.expectEqual(@as(u8, 1), grid.get(2, 3));
    try std.testing.expectEqual(@as(u8, 0), grid.get(1, 2));
    try std.testing.expectEqual(@as(u8, 0), grid.get(3, 2));

    evolve(&grid);

    try std.testing.expectEqual(@as(u8, 1), grid.get(1, 2));
    try std.testing.expectEqual(@as(u8, 1), grid.get(2, 2));
    try std.testing.expectEqual(@as(u8, 1), grid.get(3, 2));
    try std.testing.expectEqual(@as(u8, 0), grid.get(2, 1));
    try std.testing.expectEqual(@as(u8, 0), grid.get(2, 3));
}

test "starting_pattern" {
    const allocator = std.testing.allocator;

    var grid = try init(allocator, 5, 5);
    defer deinit(&grid, allocator);

    const pattern =
        \\.....
        \\..*..
        \\...*.
        \\.***.
        \\.....
        ;

    try starting_pattern(&grid, pattern ++ "\n");

    try std.testing.expectEqual(@as(u8, 1), grid.get(1, 2));
    try std.testing.expectEqual(@as(u8, 1), grid.get(2, 3));
    try std.testing.expectEqual(@as(u8, 1), grid.get(3, 1));
    try std.testing.expectEqual(@as(u8, 1), grid.get(3, 2));
    try std.testing.expectEqual(@as(u8, 1), grid.get(3, 3));
}

test "starting_pattern MismatchedSize error" {
    const allocator = std.testing.allocator;

    var grid = try init(allocator, 5, 5);
    defer deinit(&grid, allocator);

    const pattern =
        \\.....
        \\..*..
        \\...*.
        \\.***.
        \\.....
        \\.....
        ;

    try std.testing.expectError(
        error.MismatchedSize,
        starting_pattern(&grid, pattern),
    );
}
