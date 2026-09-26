const std = @import("std");
const rl = @import("raylib");
const grid = @import("grid.zig");

const GameState = struct {
    screenWidth: i32 = 800,
    screenHeight: i32 = 600,
    cell_spacing: usize = 5,
    step_interval: f32,
    elapsed: f32,
    paused: bool = false,
};

pub fn run(io: std.Io, board: *grid.Grid) !void {
    var game = GameState{
        .step_interval = 0.1,
        .elapsed = 0,
    };

    var prng: std.Random.DefaultPrng = .init(blk: {
        var seed: u64 = undefined;
        std.Io.random(io, std.mem.asBytes(&seed));
        break :blk seed;
    });

    rl.initWindow(game.screenWidth, game.screenHeight, "Conways Game of Life");
    defer rl.closeWindow();

    rl.setTargetFPS(60);

    while (!rl.windowShouldClose()) {
        while (true) {
            const key = rl.getKeyPressed();
            if (key == .null) break;

            switch (key) {
                .space => { game.paused = !game.paused; game.elapsed = 0; },
                .n => if (game.paused) { grid.evolve(board); },
                .r => if (game.paused) { grid.randomSeed(board, &prng); },
                else => {},
            }
        }

        if (!game.paused) {
            game.elapsed += rl.getFrameTime();
            if (game.elapsed >= game.step_interval) {
                grid.evolve(board);
                game.elapsed -= game.step_interval;
            }
        }

        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(.black);

        for (0..board.rows) |row| {
            for (0..board.cols) |col| {
                if (board.get(row, col) == 1) {
                    const x: i32 = @intCast(col * game.cell_spacing);
                    const y: i32 = @intCast(row * game.cell_spacing);
                    const size: i32 = @intCast(game.cell_spacing - 1);
                    rl.drawRectangle(x, y, size, size, .green);
                }
            }
        }
    }
}
