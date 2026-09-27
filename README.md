# Game of Life

Conway’s Game of Life written in Zig with raylib. This is a learning
project exploring memory management, file parsing, graphics, and input.

The original Mojo/Pygame implementation is preserved in mojo/ (mojo/).

## Features

Graphical display targeting 60 FPS
Simulation advancing 10 generations per second
Pattern loading from text files
Random board generation
Pause and single-step controls

## Build and run

Requires Zig 0.16.0 and the platform libraries needed by raylib.
Zig downloads the raylib dependency on the first build.

```bash
zig build run -- patterns/glider.txt
```

For an optimized build:

```bash
zig build -Doptimize=ReleaseFast
./zig-out/bin/game_of_life patterns/glider.txt
```

Included patterns: glider, blinker, toad, pulsar, and Gosper glider gun.

Run the glider gun with `zig build run -- patterns/gosper-glider-gun.txt`.
It emits a glider every 30 generations (about three seconds at the default speed).
The pattern comes from [LifeWiki](https://conwaylife.com/wiki/Gosper_glider_gun).
On the current wraparound board, emitted gliders can eventually return and collide
with the gun.

## Controls

| Key    | Action                              |
|---     |---                                  |
| Space  | Pause or resume                     |
| N      | Advance one generation while paused |
| R      | Randomize the board while paused    |
| Escape | Close the window                    |

## Pattern format

Use * for living cells and . for dead cells, with one row per line:

```text
.*.
..*
***
```

Patterns load at the top-left of the board and must fit within its
dimensions. A final newline is optional.
