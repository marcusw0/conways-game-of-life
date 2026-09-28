const std = @import("std");
const rl = @import("raylib");
const grid = @import("grid.zig");

const GameState = struct {
    screenWidth: i32 = 800,
    screenHeight: i32 = 600,
    footerHeight: i32 = 40,
    fontSize: f32 = 16,
    text_buffer: [128]u8 = undefined,
    step_interval: f32 = 0.1,
    elapsed: f32 = 0,
    controls: [:0]const u8 = "Space: pause | N: step | R: randomize | Scroll: zoom",
};

pub fn run(io: std.Io, board: *grid.Grid) !void {
    var game = GameState{};
    var paused: bool = false;

    var prng: std.Random.DefaultPrng = .init(blk: {
        var seed: u64 = undefined;
        std.Io.random(io, std.mem.asBytes(&seed));
        break :blk seed;
    });

    rl.setConfigFlags(.{ .window_resizable = true });
    rl.initWindow(game.screenWidth, game.screenHeight, "Conways Game of Life");
    defer rl.closeWindow();

    const font = try rl.loadFont("assets/fonts/Lexend-Regular.ttf");
    defer rl.unloadFont(font);

    rl.setTargetFPS(60);
    var camera = rl.Camera2D{
        .target = .{ .x = 0, .y = 0 },
        .offset = .{ .x = 0, .y = 0 },
        .rotation = 0,
        .zoom = 1,
    };

    while (!rl.windowShouldClose()) {
        while (true) {
            const key = rl.getKeyPressed();
            if (key == .null) break;

            switch (key) {
                .space => { paused = !paused; game.elapsed = 0; },
                .n => if (paused) { grid.evolve(board); },
                .r => if (paused) { grid.randomSeed(board, &prng); },
                else => {},
            }
        }

        const wheel = rl.getMouseWheelMove();
        if (wheel != 0) {
            camera.zoom = std.math.clamp(camera.zoom + wheel * 0.1, 0.1, 20.0);
        }

        if (rl.isMouseButtonDown(.middle)) {
            const delta = rl.getMouseDelta();
            camera.target.x -= delta.x / camera.zoom;
            camera.target.y -= delta.y / camera.zoom;
        }

        if (!paused) {
            game.elapsed += rl.getFrameTime();
            if (game.elapsed >= game.step_interval) {
                grid.evolve(board);
                game.elapsed -= game.step_interval;
            }
        }

        const win_height = rl.getScreenHeight() - game.footerHeight;
        const cell_size: f32 = 5;

        var population: u32 = 0;

        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(.black);

        rl.beginScissorMode(0, 0, rl.getScreenWidth(), @max(0, win_height));
        rl.beginMode2D(camera);

        for (0..board.rows) |row| {
            for (0..board.cols) |col| {
                if (board.get(col, row) == 1) {
                    population += 1;
                    const rec =rl.Rectangle{
                        .height = cell_size * 0.8,
                        .width  = cell_size * 0.8,
                        .x = @as(f32, @floatFromInt(col)) * cell_size,
                        .y = @as(f32, @floatFromInt(row)) * cell_size,
                    };
                    rl.drawRectangleRec(rec, .green);
                }
            }
        }
        rl.endMode2D();
        rl.endScissorMode();

        const status_text = try std.fmt.bufPrintZ(
            &game.text_buffer,
            "{s} | Population: {d} | Zoom: {d:.1}x",
            .{ if (paused) "Paused" else "Running", population, camera.zoom },
        );

        rl.drawRectangle(0, win_height, rl.getScreenWidth(), game.footerHeight, .blank);
        rl.drawTextEx(font, game.controls,
            .{ .x = 10, .y = @floatFromInt(win_height) },
            game.fontSize, 1, .ray_white,
            );
        rl.drawTextEx(font, status_text,
            .{ .x = 10, .y = @floatFromInt(win_height + 18) },
            game.fontSize, 1, .ray_white,
            );
    }
}
