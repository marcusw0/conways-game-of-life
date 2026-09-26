from grid_buffer import Grid
from std.python import Python, PythonObject

def run_display(
    var grid: Grid,
    window_height: Int = 600,
    window_width: Int = 800,
    background_color: String = "black",
    cell_color: String = "green",
    pause: Float64 = 0.1,
) raises -> None:
    var pygame = Python.import_module("pygame")

    pygame.init()

    var window = pygame.display.set_mode(
        Python.tuple(window_width, window_height)
    )
    pygame.display.set_caption("Conway's Game of Life")

    var cell_height = Float64(window_height) / Float64(grid.rows)
    var cell_width = Float64(window_width) / Float64(grid.cols)
    var border_size = 1
    var cell_fill_color = pygame.Color(cell_color)
    var background_fill_color = pygame.Color(background_color)
    var paused = True
    var clock = pygame.time.Clock()
    var elapsed: Float64 = 0.0
    var interval = max(pause, 0.001)

    # -1 = not drawing, 0 = erase, 1 = paint
    var draw_state: Int = -1

    # Geometry stays fixed until the board or window dimensions change.
    var cell_rects = List[PythonObject]()
    for row in range(grid.rows):
        for col in range(grid.cols):
            cell_rects.append(Python.tuple(
                Float64(col) * cell_width,
                Float64(row) * cell_height,
                cell_width - Float64(border_size),
                cell_height - Float64(border_size),
            ))

    var running = True
    while running:
        elapsed += Float64(py=clock.tick(60)) / 1000.0
        # Poll for events
        for event in pygame.event.get():
            if event.type == pygame.QUIT:
                # Quit if the window is closed
                running = False

            elif event.type == pygame.KEYDOWN:
                if event.key == pygame.K_ESCAPE:
                    running = False
                elif event.key == pygame.K_SPACE:
                    paused = not paused
                    elapsed = 0.0
                elif event.key == pygame.K_n:
                    if paused:
                        grid.evolve()
                elif event.key == pygame.K_c:
                    paused = True
                    for row in range(grid.rows):
                        for col in range(grid.cols):
                            grid[row, col] = 0
                elif event.key == pygame.K_r:
                    grid = Grid.random(grid.rows, grid.cols)
                    elapsed = 0.0

            elif event.type == pygame.MOUSEBUTTONDOWN:
                if paused:
                    if event.button == 1:
                        draw_state = 1
                    elif event.button == 3:
                        draw_state = 0

                    if draw_state != -1:
                        var x = Float64(py=event.pos[0])
                        var y = Float64(py=event.pos[1])

                        if (
                            x >= 0.0
                            and x < Float64(window_width)
                            and y >= 0.0
                            and y < Float64(window_height)
                        ):
                            var col = Int(x / cell_width)
                            var row = Int(y / cell_height)
                            grid[row, col] = draw_state


            elif event.type == pygame.MOUSEMOTION:
                if paused and draw_state != -1:
                    var x = Float64(py=event.pos[0])
                    var y = Float64(py=event.pos[1])

                    if (
                        x >= 0.0
                        and x < Float64(window_width)
                        and y >= 0.0
                        and y < Float64(window_height)
                    ):
                        var col = Int(x / cell_width)
                        var row = Int(y / cell_height)
                        grid[row, col] = draw_state

            elif event.type == pygame.MOUSEBUTTONUP:
                if event.button == 1 or event.button == 3:
                    draw_state = -1


        if not running:
            break

        if paused:
            elapsed = 0.0
        elif elapsed >= interval:
            grid.evolve()
            elapsed -= interval

        # Clear the window by painting with the background color
        window.fill(background_fill_color)

        # Draw each live cell in the grid
        for row in range(grid.rows):
            for col in range(grid.cols):
                if grid[row, col]:
                    pygame.draw.rect(
                        window,
                        cell_fill_color,
                        cell_rects[row * grid.cols + col],
                    )
        # Update the display
        pygame.display.flip()

    # Shutdown pygame cleanly
    pygame.quit()

def main() raises:
    var start = Grid.random(120, 160)
    run_display(start^)
