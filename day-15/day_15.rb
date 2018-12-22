DEBUG = false

def putd(str)
  puts str if DEBUG
end

class Position
  include Comparable
  attr_accessor :x, :y

  def initialize(x, y)
    @x, @y = x, y
  end

  def ==(o)
    o.class == self.class &&
      @x == o.x &&
      @y == o.y
  end

  def <=>(o)
    if @y == o.y
      @x <=> o.x
    else
      @y <=> o.y
    end
  end

  def hamilton_distance(o)
    (@x - o.x).abs + (@y - o.y).abs
  end

  def adjacent
    [
      Position.new(@x, @y + 1),
      Position.new(@x, @y - 1),
      Position.new(@x + 1, @y),
      Position.new(@x - 1, @y),
    ]
  end

  def to_s
    "{#{x}, #{y}}"
  end

  def inspect
    to_s
  end
end

class Unit
  attr_reader :pos, :team, :is_alive

  def initialize(pos, ascii_char)
    @pos = pos
    @team = ascii_char
    @is_alive = true
  end

  # returns false when combat is over
  def take_turn(units, field)
    targets = units.reject { |unit| unit.team == team }
    return false if targets.empty?
    target_attack_squares_in_range = targets.map { |t| field.in_range_squares(t.pos) }.flatten
    adj = @pos.adjacent
    in_range_of_target = targets.any? { |t| adj.include?(t.pos) }
    open_squares_in_range = !target_attack_squares_in_range.empty?

    if !in_range_of_target && !open_squares_in_range # can't move or attack, so end turn
      putd "ending early"
      return true
    end
    if in_range_of_target
      putd "attacking!"
      attack
    else
      putd "moving!"
      putd target_attack_squares_in_range.inspect
      move(field, target_attack_squares_in_range)
    end
    true
  end



  private

  def move(field, squares)
    # first, chose a square to target
    rss = reachable_squares(field, squares)
    min_distance = rss.map { |square| @pos.hamilton_distance(square) }.min
    putd "min_distance: #{min_distance}"
    nearest_squares = rss.select { |square| @pos.hamilton_distance(square) == min_distance }
    putd "nearest_squares: #{nearest_squares}"
    chosen_target_square = nearest_squares.sort.first
    putd "chosen_target_square: #{chosen_target_square}"

    # then, determine the best way to move in that direction
    adj_distances = @pos.adjacent.map { |adj| [adj, adj.hamilton_distance(chosen_target_square)] }.to_h
    min_distance_from_adj = adj_distances.values.min
    best_adj_options = adj_distances.select { |_, dist| dist == min_distance_from_adj }.keys
    chosen_adj = best_adj_options.sort.first

    # update the field to reflect our new position
    field.put(@pos, '.')
    @pos = chosen_adj
    field.put(@pos, team)
  end

  def attack

  end

  def reachable_squares(field, squares)
    squares.select { |square| field.path_exists?(@pos, square) }
  end
end

class Battlefield
  def initialize(grid)
    @grid = grid
  end

  def get(pos)
    @grid[pos.y][pos.x]
  end

  def put(pos, val)
    @grid[pos.y][pos.x] = val
  end

  def in_range_squares(pos)
    pos.adjacent
      .reject { |p| get(p) != '.' }
  end

  def path_exists?(src, dest)
    # putd "does path exist between #{src} and #{dest}?"
    seen_positions = [src]
    in_range_squares(src)
      .map { |adj| path_exists_helper(adj, dest, seen_positions) }
      .inject(false) { |past, in_range| past || in_range }
  end

  def to_s
    @grid.map(&:join).join("\n")
  end

  private

  def path_exists_helper(src, dest, seen_positions)
    return false if seen_positions.include?(src) || get(src) != '.'
    return true if src == dest

    seen_positions.push(src)
    in_range_squares(src)
      .map { |adj| path_exists_helper(adj, dest, seen_positions) }
      .inject(false) { |past, in_range| past || in_range }
  end
end

grid = File.readlines('example_movement.txt').map { |line| line.chomp.chars }

initial_units = []
grid.each_with_index do |row, i|
  row.each_with_index do |env, j|
    unless %w(. #).include?(env)
      initial_units << Unit.new(Position.new(j, i), env)
    end
  end
end

units = Marshal.load(Marshal.dump(initial_units))
battlefield = Battlefield.new(grid)

def round(units, field)
  position_to_unit = units.select(&:is_alive).map { |unit| [unit.pos, unit] }.to_h
  starting_positions = units.map(&:pos).sort
  starting_positions.each do |pos|
    unit = position_to_unit[pos]
    putd "curr unit: #{unit.team} #{pos}"
    continue_fighting = unit.take_turn(units.reject { |u| u.pos == pos }, field)
    return false unless continue_fighting
  end
  true
end

puts "Initial battlefield"
puts battlefield
i = 1
3.times do
  round(units, battlefield)
  puts "Round #{i}"
  puts battlefield
  i += 1
end

puts
puts
