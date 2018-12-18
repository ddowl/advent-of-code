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
    if @y != o.y
      @x <=> o.x
    else
      @y <=> o.y
    end
  end
end

class Cart
  include Comparable

  attr_reader :position, :direction

  CART_DIRECTION = {
    '^' => :north,
    '>' => :east,
    'v' => :south,
    '<' => :west,
  }

  CART_SHAPES = {
    :north => '^',
    :east => '>',
    :south => 'v',
    :west => '<',
  }

  INTERSECTION_OPTIONS = [:left, :straight, :right]

  def initialize(position, initial_shape)
    @position = position
    @direction = CART_DIRECTION[initial_shape]
    @intersection_opt_idx = 0
  end

  def shape
    CART_SHAPES[@direction]
  end

  def tick(tracks)
    next_pos = get_next_position
    env = tracks[next_pos.y][next_pos.x]
    new_direction = get_next_direction(env)

    @position = next_pos
    @direction = new_direction
  end

  def <=>(o)
    @position <=> o.position
  end

  private

  def get_next_position
    dx, dy = case @direction
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

  def get_next_direction(env)
    case @direction
    when :north
      if env == '/'
        :east
      elsif env == '\\'
        :west
      elsif env == '+'
        turn = INTERSECTION_OPTIONS[@intersection_opt_idx]
        @intersection_opt_idx = (@intersection_opt_idx + 1) % INTERSECTION_OPTIONS.size
        case turn
        when :left
          :west
        when :straight
          @direction
        when :right
          :east
        end
      elsif env == '-' || env == '|'
        @direction
      else
        raise "how tf did we get off the tracks? #{env} #{next_pos.inspect}"
      end
    when :south
      if env == '/'
        :west
      elsif env == '\\'
        :east
      elsif env == '+'
        turn = INTERSECTION_OPTIONS[@intersection_opt_idx]
        @intersection_opt_idx = (@intersection_opt_idx + 1) % INTERSECTION_OPTIONS.size
        case turn
        when :left
          :east
        when :straight
          @direction
        when :right
          :west
        end
      elsif env == '-' || env == '|'
        @direction
      else
        raise "how tf did we get off the tracks? #{env} #{next_pos.inspect}"
      end
    when :west
      if env == '/'
        :south
      elsif env == '\\'
        :north
      elsif env == '+'
        turn = INTERSECTION_OPTIONS[@intersection_opt_idx]
        @intersection_opt_idx = (@intersection_opt_idx + 1) % INTERSECTION_OPTIONS.size
        case turn
        when :left
          :south
        when :straight
          @direction
        when :right
          :north
        end
      elsif env == '-' || env == '|'
        @direction
      else
        raise "how tf did we get off the tracks? #{env} #{next_pos.inspect}"
      end
    when :east
      if env == '/'
        :north
      elsif env == '\\'
        :south
      elsif env == '+'
        turn = INTERSECTION_OPTIONS[@intersection_opt_idx]
        @intersection_opt_idx = (@intersection_opt_idx + 1) % INTERSECTION_OPTIONS.size
        case turn
        when :left
          :north
        when :straight
          @direction
        when :right
          :south
        end
      elsif env == '-' || env == '|'
        @direction
      else
        raise "how tf did we get off the tracks? #{env} #{next_pos.inspect}"
      end
    else
      raise "wtf??"
    end
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
puts carts_on_tracks(tracks, carts)

cart_positions = []
# part 1
until dups(cart_positions)
  carts.sort.reverse.each do |c|
    cart_positions = carts.map(&:position)
    d = dups(cart_positions)
    # puts carts_on_tracks(tracks, carts)
    # p cart_positions
    if d
      p d
      break
    end

    c.tick(tracks)
  end
end

puts

# # part 2
# carts = Marshal.load(Marshal.dump(initial_carts))
# until carts.size == 1
#   carts.sort.reverse.each do |c|
#     cart_positions = carts.map(&:position)
#     d = dups(cart_positions)
#     # puts carts_on_tracks(tracks, carts)
#     # p cart_positions
#     if d
#       # p d
#       carts.delete_if { |cart| cart.position == d }
#       p carts
#       if carts.size == 1
#         p carts.first
#         break
#       end
#     end
#
#     c.tick(tracks)
#   end
# end
#
# puts