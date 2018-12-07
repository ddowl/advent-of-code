# Strategy: Read in all coordinates and assign them integer ids. Make a Grid the size of the largest x, y coordinate.
# Fill in the grid with the integer values of the closest coordinate according to Manhattan distance. If there's a tie,
# leave it a nil value. We can determine if a coordinate's area is infinite by checking the cells on the grid
# border. We can sum up the # of cells that hold each coordinate's id and group_by the id.

class Array
  def second
    self[1]
  end
end

class Point
  attr_reader :x, :y

  def initialize(x, y)
    @x = x
    @y = y
  end

  def to_s
    "{#{@x}, #{@y}}"
  end

  def inspect
    to_s
  end

  def manhattan_distance(other)
    (@x - other.x).abs + (@y - other.y).abs
  end

  # Returns an array of the closest points to this one
  # based on manhattan distance
  def closest_points(points)
    distances = points.map { |point| [manhattan_distance(point), point] }
    distance_hash = Hash[distances.group_by(&:first).map { |k, a| [k, a.map(&:last)] }]
    # p distance_hash
    # p distance_hash.keys.min
    distance_hash[distance_hash.keys.min]
  end

  def distances_to_all_points(points)
    points.map { |point| manhattan_distance(point) }.sum
  end
end

def points_on_border(grid)
  top = grid[0]
  bottom = grid[-1]
  left = grid.map { |row| row[0] }
  right = grid.map { |row| row[-1] }
  (top + bottom + left + right).uniq.reject(&:nil?)
end

def area_sizes(grid)
  grid.map do |row|
    row
      .group_by(&:itself)
      .transform_values(&:size)
      .reject { |k, _| k.nil? }
  end.inject({}) do |row1, row2|
    row1.merge(row2) { |k, a_val, b_val| a_val + b_val }
  end
end

coords = File
           .readlines('input.txt')
           .map { |line| line.scan(/(\d+), (\d+)/).first }
           .map { |x, y| Point.new(x.to_i, y.to_i) }
# p coords

max_coord = [coords.map(&:x).max, coords.map(&:y).max]
# p max_coord

grid = []
# fill in grid with nearest point
(0...max_coord.first + 1).each do |row_i|
  row = []
  (0...max_coord.second + 1).each do |col_i|
    closest_points = Point.new(row_i, col_i).closest_points(coords)
    row << (closest_points.size == 1 ? closest_points.first : nil) # don't count ties
  end
  grid << row
end
# p grid



points_with_infinite_area = points_on_border(grid)

sizes = area_sizes(grid)
# p sizes
p sizes
    .reject { |k, _| points_with_infinite_area.include?(k) }
    .max_by { |_, v| v }
    .second


threshold = 10000
region_size = 0
(0...max_coord.first + 1).each do |row_i|
  (0...max_coord.second + 1).each do |col_i|
    distance_to_coords = Point.new(row_i, col_i).distances_to_all_points(coords)
    if distance_to_coords < threshold
      region_size += 1
    end
  end
end
p region_size

puts
