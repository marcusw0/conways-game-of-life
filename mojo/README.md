# Mojo implementation

The original Mojo/Pygame implementation is kept here for reference and comparison
with the Zig implementation at the repository root.

From the repository root:

```sh
cd mojo
pixi run mojo build life.mojo -o life
pixi run ./life
```

Pixi creates a local environment in this directory on first use. The board starts
paused. Space toggles pause, N steps while paused, C clears, and R randomizes.
While paused, drag with the left mouse button to draw or the right mouse button
to erase.

The fixed window has an 800 × 600 board area and the original 60-pixel footer,
showing all controls, running/paused status, and live population. The simulation
uses a 120 × 160 board and a 0.1-second generation interval.
