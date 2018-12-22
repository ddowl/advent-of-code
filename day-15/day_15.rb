DEBUG = true

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
    # p targets
    return false if targets.empty?
    target_attack_squares_in_range = targets.map { |t| t.in_range_squares(field) }.flatten
    in_range_of_target = target_attack_squares_in_range.any? { |target_pos| target_pos == @pos }
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

  def in_range_squares(field)
    adjacent_squares
      .reject { |pos| field[pos.y][pos.x] != '.' }
  end

  private

  def move(field, squares)
    # first, chose a square to target
    reachable_squares = reachable(field, squares)
    min_distance = reachable_squares.map { |square| @pos.hamilton_distance(square) }.min
    putd "min_distance: #{min_distance}"
    nearest_squares = reachable_squares.select { |square| @pos.hamilton_distance(square) == min_distance }
    putd "nearest_squares: #{nearest_squares}"
    chosen_target_square = nearest_squares.sort.first
    putd "chosen_target_square: #{chosen_target_square}"

    # then, determine the best way to move in that direction
    adj_distances = adjacent_squares.map { |adj| [adj, adj.hamilton_distance(chosen_target_square)] }.to_h
    min_distance_from_adj = adj_distances.values.min
    best_adj_options = adj_distances.select { |_, dist| dist == min_distance_from_adj }.keys
    chosen_adj = best_adj_options.sort.first

    # update the field to reflect our new position
    field[@pos.y][@pos.x] = '.'
    @pos = chosen_adj
    field[@pos.y][@pos.x] = team
  end

  def attack

  end



  def adjacent_squares
    [
      Position.new(@pos.x, @pos.y + 1),
      Position.new(@pos.x, @pos.y - 1),
      Position.new(@pos.x + 1, @pos.y),
      Position.new(@pos.x - 1, @pos.y),
    ]
  end

  def reachable(field, squares)
    squares
  end
end

class Battlefield
  def initialize(grid)
    @grid = grid
  end

  def to_s
    @grid.map(&:join).join("\n")
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
  round(units, grid)
  puts "Round #{i}"
  puts battlefield
  i += 1
end

puts
