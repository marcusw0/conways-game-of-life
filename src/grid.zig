const std = @import("std");

pub const Grid = struct {
    rows: usize,
    cols: usize,
    data: []u8,
    next_data: []u8,

    pub fn get(self: Grid, row: usize, col: usize) u8 {
        std.debug.assert(row < self.rows);
        std.debug.assert(col < self.cols);
        return self.data[row * self.cols + col];
    }

    pub fn set(self: *Grid, row: usize, col: usize, value: u8) void {
        std.debug.assert(row < self.rows);
        std.debug.assert(col < self.cols);
        self.data[row * self.cols + col] = value;
    }
};

pub fn init(allocator: std.mem.Allocator, rows: usize, cols: usize) !Grid {
    const count: usize = rows * cols;

    const data_buffer = try allocator.alloc(u8, count);
    @memset(data_buffer, 0);
    errdefer allocator.free(data_buffer);

    const next_buffer = try allocator.alloc(u8, count);
    @memset(next_buffer, 0);

    return Grid{
        .rows = rows,
        .cols = cols,
        .data = data_buffer,
        .next_data = next_buffer,
    };
}

pub fn deinit(self: *Grid, allocator: std.mem.Allocator) void {
    allocator.free(self.data);
    allocator.free(self.next_data);
}

pub fn draw(self: Grid, writer: *std.Io.Writer) !void {
    for (0..self.rows) |row| {
        for (0..self.cols) |col| {
            if (self.get(row, col) == 1) {
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

            const num_neighbors = (
                self.get(row_above, col_left)
                + self.get(row_above, j)
                + self.get(row_above, col_right)
                + self.get(i, col_left)
                + self.get(i, col_right)
                + self.get(row_below, col_left)
                + self.get(row_below, j)
                + self.get(row_below, col_right)
            );

            var new_state: u8 = 0;
            if (num_neighbors == 3 or (self.get(i, j) == 1 and num_neighbors == 2)) {
                new_state = 1;
            }

            self.next_data[i * self.cols + j] = new_state;
        }
    }

    const old_data = self.data;
    self.data = self.next_data;
    self.next_data = old_data;
}

pub fn starting_pattern(self: *Grid, pattern: []const u8) !void {
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
                '.' => self.set(row_index, col_index, 0),
                '*' => self.set(row_index, col_index, 1),
                else => return error.UnkownCharacter,
            }
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
