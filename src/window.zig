const std = @import("std");
const rl = @import("raylib");
const grid = @import("grid.zig");

const GameState = struct {
    screenWidth: i32 = 800,
    screenHeight: i32 = 600,
    footerHeight: i32 = 40,
    fontSize: i32 = 12,
    text_buffer: [128]u8 = undefined,
    step_interval: f32 = 0.1,
    elapsed: f32 = 0,
    paused: bool = false,
    controls: [:0]const u8 = "Space: pause | N: step | R: randomize",
};

pub fn run(io: std.Io, board: *grid.Grid) !void {
    var game = GameState{};

    var prng: std.Random.DefaultPrng = .init(blk: {
        var seed: u64 = undefined;
        std.Io.random(io, std.mem.asBytes(&seed));
        break :blk seed;
    });

    rl.setConfigFlags(.{ .window_resizable = true });
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

        const win_height = rl.getScreenHeight() - game.footerHeight;

        const cell_width = @as(f32, @floatFromInt(rl.getScreenWidth())) /
            @as(f32, @floatFromInt(board.cols));

        const cell_height = @as(f32, @floatFromInt(win_height)) /
            @as(f32, @floatFromInt(board.rows));

        var population: u32 = 0;

        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(.black);

        for (0..board.rows) |row| {
            for (0..board.cols) |col| {
                if (board.get(row, col) == 1) {
                    population += 1;
                    const rec =rl.Rectangle{
                        .height = cell_height * 0.8,
                        .width  = cell_width * 0.8,
                        .x = @as(f32, @floatFromInt(col)) * cell_width,
                        .y = @as(f32, @floatFromInt(row)) * cell_height,
                    };
                    rl.drawRectangleRec(rec, .green);
                }
            }
        }
        const status_text = try std.fmt.bufPrintZ(
            &game.text_buffer,
            "{s} | Population: {d}",
            .{ if (game.paused) "Paused" else "Running", population},
        );

        rl.drawRectangle(0, win_height, rl.getScreenWidth(), game.footerHeight, .blank);
        rl.drawText(game.controls, 0, win_height, game.fontSize, .ray_white);
        rl.drawText(status_text, 0, win_height + 18, game.fontSize, .ray_white);
    }
}
