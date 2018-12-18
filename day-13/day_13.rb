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

  def to_s
    "{#{x}, #{y}}"
  end

  def inspect
    to_s
  end
end

class Cart
  include Comparable

  attr_reader :position
  attr_accessor :collided

  CART_SHAPES = {
    :north => '^',
    :east => '>',
    :south => 'v',
    :west => '<',
  }

  INTERSECTION_OPTIONS = [:left, :straight, :right]
  TRACK_CHARS = %w(/ \\ + - |)
  DIRECTIONS = [:north, :east, :south, :west]

  def initialize(position, initial_shape)
    @position = position
    @direction_idx = CART_SHAPES.values.index(initial_shape)
    @intersection_opt_idx = 0
    @collided = false
  end

  def shape
    CART_SHAPES[direction]
  end

  def direction
    DIRECTIONS[@direction_idx]
  end

  def tick(tracks)
    @position = get_next_position
    env = tracks[@position.y][@position.x]
    @direction_idx = get_next_direction_idx(env)
  end

  def <=>(o)
    @position <=> o.position
  end

  def to_s
    "{pos:#{position}, direction:#{direction}}"
  end

  def inspect
    to_s
  end

  private

  def get_next_position
    dx, dy = case direction
             when :north
               [0, -1]
             when :east
               [1, 0]
             when :south
               [0, 1]
             when :west
               [-1, 0]
             else
               raise "wtf?"
             end

    Position.new(@position.x + dx, @position.y + dy)
  end

  def get_next_direction_idx(env)
    raise "how tf did we get off the tracks? #{env} #{@position}" unless TRACK_CHARS.include?(env)
    raise "wait, what?" unless DIRECTIONS.include?(direction)
    return @direction_idx if env == '-' || env == '|'
    return intersection if env == '+'

    case direction
    when :north
      if env == '/'
        DIRECTIONS.index(:east)
      elsif env == '\\'
        DIRECTIONS.index(:west)
      end
    when :south
      if env == '/'
        DIRECTIONS.index(:west)
      elsif env == '\\'
        DIRECTIONS.index(:east)
      end
    when :west
      if env == '/'
        DIRECTIONS.index(:south)
      elsif env == '\\'
        DIRECTIONS.index(:north)
      end
    when :east
      if env == '/'
        DIRECTIONS.index(:north)
      elsif env == '\\'
        DIRECTIONS.index(:south)
      end
    end
  end

  def intersection
    turn = INTERSECTION_OPTIONS[@intersection_opt_idx]
    @intersection_opt_idx = (@intersection_opt_idx + 1) % INTERSECTION_OPTIONS.size
    idx = case turn
          when :left
            @direction_idx - 1
          when :straight
            @direction_idx
          when :right
            @direction_idx + 1
          end
    idx % DIRECTIONS.size
  end
end

def carts_on_tracks(tracks, carts)
  cave = Marshal.load(Marshal.dump(tracks))
  carts.each do |cart|
    x, y = cart.position.x, cart.position.y
    cave[y][x] = cart.shape
  end
  cave.map(&:join).join("\n")
end

def dups(arr)
  arr.detect { |e| arr.count(e) > 1 }
end


# ===================================================================== #


tracks = File.readlines('input.txt').map { |line| line.chomp.chars }

initial_carts = []
tracks.each_with_index do |row, i|
  row.each_with_index do |env, j|
    if Cart::CART_SHAPES.values.include?(env)
      cart = Cart.new(Position.new(j, i), env)
      initial_carts << cart

      if cart.direction == :north || cart.direction == :south
        row[j] = '|'
      else
        row[j] = '-'
      end
    end
  end
end

carts = Marshal.load(Marshal.dump(initial_carts))

# Try to model tracks and carts together in a model that can be "tick"'d atomically

cart_positions = []
# part 1
until dups(cart_positions)
  carts.sort.reverse.each do |c|
    c.tick(tracks)
    cart_positions = carts.map(&:position)
    d = dups(cart_positions)
    if d
      break
    end
  end
end

puts "part 1: #{dups(cart_positions)}"

# part 2
carts = Marshal.load(Marshal.dump(initial_carts))

loop do
  carts = carts.sort
  carts.each do |cart|
    cart.tick(tracks)
    cart_positions = carts.map(&:position)
    d = dups(cart_positions)
    if d
      carts.select { |c| c.position == d }.each { |c| c.collided = true }
    end
  end

  carts = carts.delete_if(&:collided)

  break if carts.size == 1
end

puts "part 2: #{carts.first}"
puts
