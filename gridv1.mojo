from std import random

@fieldwise_init
struct Grid(Copyable, Writable):
    var rows: Int
    var cols: Int
    var data: List[List[Int]]


    def write_to(self, mut writer: Some[Writer]):
        for row in range(self.rows):
            for col in range(self.cols):
                if self[row, col] == 1:
                    writer.write_string("*") # If cell is populated, append an asterisk
                else:
                    writer.write_string(" ")
            if row != self.rows - 1:
                writer.write_string("\n")

    def __getitem__(self, row: Int, col: Int) -> Int:
        return self.data[row][col]

    def __setitem__(mut self, row: Int, col: Int, value: Int) -> None:
        self.data[row][col] = value

    @staticmethod
    def random(rows: Int, cols: Int) -> Self:
        # Seed the random number generator using the current time
        random.seed()

        var data: List[List[Int]] = []

        for _ in range(rows):
            var row_data: List[Int] = []
            for _ in range(cols):
                row_data.append(Int(random.random_si64(0, 1)))
            data.append(row_data^)

        return Self(rows, cols, data^)

    def evolve(self) -> Self:
        var next_generation = List[List[Int]]()

        for row in range(self.rows):
            var row_data = List[Int]()

            # Calculate neighboring row indices, handling "wrap-around"
            var row_above = (row - 1) % self.rows
            var row_below = (row + 1) % self.rows

            for col in range(self.cols):
                # Calculate neighboring column indices, handling "wrap-around"
                var col_left = (col - 1) % self.cols
                var col_right = (col + 1) % self.cols

                # Determine number of populated cells around the current cell
                var num_neighbors = (
                    self[row_above, col_left]
                    + self[row_above, col]
                    + self[row_above, col_right]
                    + self[row, col_left]
                    + self[row, col_right]
                    + self[row_below, col_left]
                    + self[row_below, col]
                    + self[row_below, col_right]
                )

                var new_state = 0
                if self[row, col] == 1 and (
                    num_neighbors == 2 or num_neighbors == 3
                ):
                    new_state = 1
                elif self[row, col] == 0 and num_neighbors == 3:
                    new_state = 1
                row_data.append(new_state)

            next_generation.append(row_data^)

        return Self(self.rows, self.cols, next_generation^)

