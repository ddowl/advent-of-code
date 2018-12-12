# This one should be pretty simple. There's a well-defined process to compute a power_level based on (x,y) coordinates
# and a serial number. The first step is to construct a 300x300 grid of these power_level values. Figuring out the
# largest 3x3 square should just be another traversal.

GRID_SERIAL_NUMBER = 1133
GRID_SIZE = 300

def power_level(x, y, serial)
  rack_id = x + 10
  level = rack_id * y
  level += serial
  level *= rack_id
  level = (level / 100) % 10 # keep the hundreds digit
  level - 5
end

# puts power_level(122, 79, 57)
# puts power_level(217, 196, 39)
# puts power_level(101, 153, 71)

# 3rd dimension of grid is a cache of power_level sums for different square sizes
grid = []
(1..GRID_SIZE).each do |x|
  row = []
  (1..GRID_SIZE).each do |y|
    cache = Array.new(GRID_SIZE)
    cache[0] = power_level(x, y, GRID_SERIAL_NUMBER)
    row << cache
  end
  grid << row
end

max_level = 0
max_coords = [0, 0]
(2..GRID_SIZE).each do |square_size|
  p square_size
  (0..(GRID_SIZE - square_size)).each do |x|
    (0..(GRID_SIZE - square_size)).each do |y|
      cache = grid[x][y]
      last_power_square = cache[square_size - 2]
      # need to add in rightmost col and bottommost row to this
      bottommost_row = (x...(x + square_size)).map { |i| grid[i][y + square_size - 1][0] }
      rightmost_col = (y...(y + square_size)).map { |j| grid[x + square_size - 1][j][0] }

      level_from_square_at_coord = bottommost_row.sum + rightmost_col.sum + last_power_square
      cache[square_size - 1] = level_from_square_at_coord

      if level_from_square_at_coord > max_level
        max_level = level_from_square_at_coord
        max_coords = [x + 1, y + 1, square_size]
      end
    end
  end
end

p "serial: #{GRID_SERIAL_NUMBER}"
p "max level: #{max_level}"
p "max coords: #{max_coords}"

puts
