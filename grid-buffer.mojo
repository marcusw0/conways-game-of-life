from std import random

@fieldwise_init
struct Grid(Copyable, Writable):
    var rows: Int
    var cols: Int
    var data: List[Int]
    var next_data: List[Int]


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
        return self.data[row * self.cols + col]

    def __setitem__(mut self, row: Int, col: Int, value: Int) -> None:
        self.data[row * self.cols + col] = value

    @staticmethod
    def random(rows: Int, cols: Int) -> Self:
        # Seed the random number generator using the current time
        random.seed()

        var data = List[Int]()
        var next_data = List[Int]()

        for _ in range(rows * cols):
            data.append(Int(random.random_si64(0, 1)))
            next_data.append(0)

        return Self(rows, cols, data^, next_data^)

    def evolve(mut self):
        for row in range(self.rows):
            # Calculate neighboring row indices, handling "wrap-around"
            var row_above = (row + self.rows - 1) % self.rows
            var row_below = (row + 1) % self.rows

            for col in range(self.cols):
                # Calculate neighboring column indices, handling "wrap-around"
                var col_left = (col + self.cols - 1) % self.cols
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
                if num_neighbors == 3 or (
                    self[row, col] == 1 and num_neighbors == 2
                ):
                    new_state = 1

                self.next_data[row * self.cols + col] = new_state

        var old_data = self.data^
        self.data = self.next_data^
        self.next_data = old_data^
