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
