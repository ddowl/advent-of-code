class Fabric
  FABRIC_SIZE = 1000

  def initialize
    @fabric = Array.new(FABRIC_SIZE) {Array.new(FABRIC_SIZE, 0)}
  end

  def mark(claim)
    claim.x_range.each do |i|
      claim.y_range.each do |j|
        # p [i, j]
        @fabric[i][j] += 1
      end
    end
  end

  def num_overlaps()
    @fabric.flatten.select {|pos| pos > 1}.size
  end
end

class Claim
  attr_reader :x_range, :y_range

  def initialize(id, x, y, width, height)
    @id = id
    @x_range = (x...x + width)
    @y_range = (y...y + height)
  end

  def overlaps?(other)
    ranges_overlap?(@x_range, other.x_range) &&
      ranges_overlap?(@y_range, other.y_range)
  end

  private

  def ranges_overlap?(r1, r2)
    r1.cover?(r2.first) || r2.cover?(r1.first)
  end
end

fabric = Fabric.new
claims = []

File.readlines('input.txt').each do |line|
  claim_id, start_x, start_y, width, height = line.scan(/#(\d+) @ (\d+),(\d+): (\d+)x(\d+)/).first.map(&:to_i)
  claim = Claim.new(claim_id, start_x, start_y, width, height)
  claims << claim
  fabric.mark(claim)

end

puts fabric.num_overlaps

non_overlapping_claim = claims.select do |claim|
  (claims - [claim]).all? do |other_claim|
    !claim.overlaps?(other_claim)
  end
end

raise if non_overlapping_claim.size != 1

p non_overlapping_claim.first
