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
  attr_reader :pos, :team
  attr_accessor :hp, :is_alive

  def initialize(pos, ascii_char)
    @pos = pos
    @team = ascii_char
    @is_alive = true
    @hp = 200
    @attack_power = 3
  end

  # returns false when combat is over
  def take_turn(units, field)
    # dead units do not take turns
    return unless is_alive

    targets = units.reject { |unit| unit.team == team || !unit.is_alive }
    # p targets
    raise "everyone is dead!" if targets.empty?

    open_target_squares = targets
                            .map { |t| t.pos.adjacent }
                            .flatten
                            .select { |p| field.open?(p) }
    can_move = !open_target_squares.empty?

    in_range_of_target = !in_attack_range(targets).empty?
    if !in_range_of_target && !can_move # can't move or attack, so end turn
      putd "ending early"
      return
    end

    unless in_range_of_target
      putd "moving!"
      putd open_target_squares.inspect
      move(field, open_target_squares)
    end

    # we may have moved into the range of a target, so recompute
    targets_in_range = in_attack_range(targets)
    unless targets_in_range.empty?
      putd "attacking!"
      putd "targets in range: #{targets_in_range.inspect}"
      attack_weakest_target(field, targets_in_range)
    end
  end


  private

  def move(field, squares)
    # first, chose a square to target
    # it needs to be reachable
    reachable_squares = squares
                          .map { |t| [t, field.path(@pos, t)] }
                          .reject { |_, path| path.nil? }
                          .map { |t, path| [t, path.length] }
                          .to_h
    # p reachable_squares
    return if reachable_squares.empty?
    # and we'll pick the closest one

    putd "reachable_squares: #{reachable_squares.keys}"
    min_distance = reachable_squares.values.min
    putd "min_distance: #{min_distance}"
    nearest_squares = reachable_squares.select { |_, len| len == min_distance }.keys
    putd "nearest_squares: #{nearest_squares}"
    chosen_target_square = nearest_squares.sort.first
    putd "chosen_target_square: #{chosen_target_square}"

    # then, determine the best way to move in that direction
    paths_to_target = @pos.adjacent
                        .select { |adj| field.open?(adj) }
                        .map { |adj| [adj, field.path(adj, chosen_target_square)] }
                        .reject { |_, path| path.nil? }
    # p paths_to_target

    adj_distances = paths_to_target.map { |adj, path| [adj, path.length] }.to_h
    min_distance_from_adj = adj_distances.values.min
    best_adj_options = adj_distances.select { |_, dist| dist == min_distance_from_adj }.keys
    chosen_adj = best_adj_options.sort.first
    putd "moving to: #{chosen_adj}"

    # update the field to reflect our new position
    field.put(@pos, '.')
    @pos = chosen_adj
    field.put(@pos, team)
  end

  def attack_weakest_target(field, targets_in_range)
    # Choose the adjacent target with the fewest hit points
    # Resolve ties by reading order position
    by_hp = targets_in_range.group_by(&:hp)
    lowest_hp = by_hp.keys.min
    weakest_target = by_hp[lowest_hp].sort { |a, b| a.pos <=> b.pos }.first
    putd "attacking #{weakest_target.inspect}"
    weakest_target.hp -= @attack_power
    if weakest_target.hp <= 0
      weakest_target.is_alive = false
      field.put(weakest_target.pos, '.')
    end
  end

  def in_attack_range(targets)
    adj = @pos.adjacent
    targets.select { |t| adj.include?(t.pos) }
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

  def vacant?(pos)
    get(pos) == '.'
  end

  def on_field?(pos)
    0 <= pos.y && pos.y < @grid.length &&
      0 <= pos.x && pos.x < @grid[pos.y].length
  end

  def open?(pos)
    on_field?(pos) && vacant?(pos)
  end

  def path(src, dest)
    putd "finding path between #{src} and #{dest}"
    visited = []
    processing = [src]
    # map of edges from dest to src
    edges = {}

    # This nil value is a sentinel
    edges[src] = nil

    until processing.empty?
      curr = processing.shift

      return make_path(curr, edges) if curr == dest

      curr.adjacent.select { |adj| open?(adj) }.each do |adj|
        if !visited.include?(adj) && !processing.include?(adj)
          edges[adj] = curr
          processing.push(adj)
        end
      end

      visited.push(curr)
    end
    nil
  end

  def to_s
    @grid.map(&:join).join("\n")
  end

  private

  def make_path(node, edges)
    path = []
    until edges[node].nil?
      path.unshift(node)
      node = edges[node]
    end
    # prepend the first node in path
    path.unshift(node)
    path
  end
end

grid = File.readlines('input.txt').map { |line| line.chomp.chars }

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

def do_round(units, field)
  position_to_unit = units.map { |unit| [unit.pos, unit] }.to_h
  starting_positions = units.map(&:pos).sort
  starting_positions.each do |pos|
    unit = position_to_unit[pos]
    putd "curr unit: #{unit.team} #{pos} #{unit.hp}"
    unit.take_turn(units.reject { |u| u.pos == pos }, field)
  end
end

puts "Initial battlefield"
puts battlefield
units.each { |u| p u }
i = 0
begin
  loop do
    do_round(units, battlefield)

    i += 1
    puts "After Round #{i}"
    puts battlefield
    units.each { |u| p u }
  end
rescue
  puts "rescued!"
  full_rounds = i
  remaining_hp = units
                   .select(&:is_alive)
                   .map(&:hp)
                   .sum

  outcome = full_rounds * remaining_hp

  puts "full_rounds: #{full_rounds}"
  puts "remaining_hp: #{remaining_hp}"
  puts "outcome: #{outcome}"
end

puts
puts
