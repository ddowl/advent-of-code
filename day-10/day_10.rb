# Represent points in a simple class. Continue running the simulation until all points are "adjacent", as in they are
# in a small number of connected components, say some ratio of the total number of points.

class Position
  attr_accessor :x, :y
  def initialize(x, y)
    @x = x
    @y = y
  end

  def to_s
    "{#{x}, #{y}}"
  end
end

class Velocity
  attr_accessor :x, :y
  def initialize(x, y)
    @x = x
    @y = y
  end

  def to_s
    "{#{x}, #{y}}"
  end
end

# Should the Star class be immutable? We could track history more easily.
class Star
  attr_accessor :pos
  attr_reader :vel
  def initialize(pos, vel)
    @pos = pos
    @vel = vel
  end

  def tick
    pos.x += vel.x
    pos.y += vel.y
  end

  def rewind
    pos.x -= vel.x
    pos.y -= vel.y
  end

  def to_s
    "{pos=#{pos}, vel=#{vel}}"
  end
end

# a collection of stars
class Sky
  def initialize(stars)
    @stars = stars
  end

  def tick
    @stars.each(&:tick)
  end

  def rewind
    @stars.each(&:rewind)
  end

  def area
    points = @stars.map(&:pos)
    max_x = points.max_by(&:x).x
    max_y = points.max_by(&:y).y
    min_x = points.min_by(&:x).x
    min_y = points.min_by(&:y).y
    (max_x - min_x).abs * (max_y - min_y).abs
  end

  def to_s
    points = @stars.map(&:pos)
    max_x = points.max_by(&:x).x
    max_y = points.max_by(&:y).y
    min_x = points.min_by(&:x).x
    min_y = points.min_by(&:y).y

    points = points.map { |p| [p.x, p.y] }

    res = ''
    (min_y..max_y).each do |y|
      (min_x..max_x).each do |x|
        res += points.include?([x, y]) ? '#' : '.'
      end
      res += "\n"
    end
    res
  end


end

def sign_parser(str, sign_str)
  sign_str.include?('-') ? -str.to_i : str.to_i
end

stars = File.readlines('input.txt').map do |line|
  pos_x_sign, pos_x, pos_y_sign, pos_y, vel_x_sign, vel_x, vel_y_sign, vel_y =
    line.scan(/.*<([^\d]*)(\d+),([^\d]*)(\d+)>.*<([^\d]*)(\d+),([^\d]*)(\d+)>/).first

  pos_x = sign_parser(pos_x, pos_x_sign)
  pos_y = sign_parser(pos_y, pos_y_sign)
  vel_x = sign_parser(vel_x, vel_x_sign)
  vel_y = sign_parser(vel_y, vel_y_sign)
  Star.new(Position.new(pos_x, pos_y), Velocity.new(vel_x, vel_y))
end

sky = Sky.new(stars)
prev_area = (2**(0.size * 8 - 2) - 1) # Max Fixnum
curr_area = sky.area
i = 0
while curr_area < prev_area do
  i += 1
  sky.tick
  prev_area = curr_area
  curr_area = sky.area
end

puts "Frame #{i - 1}"
sky.rewind
puts sky

puts
