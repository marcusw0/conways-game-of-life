from std import time

from gridv1 import Grid
from std.python import Python

def run_display(
    var grid: Grid,
    window_height: Int = 600,
    window_width: Int = 600,
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

    var running = True
    while running:
        # Poll for events
        for event in pygame.event.get():
            if event.type == pygame.QUIT:
                # Quit if the window is closed
                running = False

        # Clear the window by painting with the background color
        window.fill(background_fill_color)

        # Draw each live cell in the grid
        for row in range(grid.rows):
            for col in range(grid.cols):
                if grid[row, col]:
                    var x = Float64(col) * cell_width + Float64(border_size)
                    var y = Float64(row) * cell_height + Float64(border_size)
                    var width = cell_width - Float64(border_size)
                    var height = cell_height - Float64(border_size)
                    pygame.draw.rect(
                        window,
                        cell_fill_color,
                        Python.tuple(x, y, width, height),
                    )

        # Update the display
        pygame.display.flip()

        # Pause
        time.sleep(pause)

        # Next generation
        grid = grid.evolve()

    # Shutdown pygame cleanly
    pygame.quit()

def main() raises:
    var start = Grid.random(240, 240)
    run_display(start^)
