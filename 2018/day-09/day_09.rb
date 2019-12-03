# Model the "circle of marbles" with a circular array, maintaining an index of the current marble. index manipulation can
# be mod'ed by the circle's length (circumference?) in order to keep the index in the circle.

trials = File
           .readlines('big_input.txt')
           .map { |line| line.scan(/(\d+) players; last marble is worth (\d+) points/).first }
           .map { |num_players, last_marble| [num_players.to_i, last_marble.to_i] }
p trials

class ArrayCircle
  def initialize
    @circle = [0]
    @curr_marble_idx = 0
  end

  def move_cursor(n)
    @curr_marble_idx = (@curr_marble_idx + n) % @circle.length
  end

  def marble_at_cursor
    @circle[@curr_marble_idx]
  end

  def delete_marble_at_cursor
    @circle.delete_at(@curr_marble_idx)
  end

  def insert_after_cursor(marble)
    @circle.insert(@curr_marble_idx + 1, marble)
  end
end

class ListCircle
  class Node
    attr_accessor :next
    attr_accessor :prev
    attr_reader   :marble
    def initialize(marble)
      @marble = marble
      @next = nil
      @prev = nil
    end

    def to_s
      "{#{marble}}"
    end
  end

  def initialize
    @curr_marble = Node.new(0)
    @curr_marble.next = @curr_marble
    @curr_marble.prev = @curr_marble
    @head = @curr_marble
  end

  def move_cursor(n)
    n.abs.times do
      # p @curr_marble
      @curr_marble = n < 0 ? @curr_marble.prev : @curr_marble.next
    end
  end

  def delete_marble_at_cursor
    # puts @curr_marble
    # puts @curr_marble.next
    # puts @curr_marble.prev
    marble_at_cursor = @curr_marble.marble
    prev = @curr_marble.prev
    @curr_marble.prev = nil
    prev.next = @curr_marble.next
    @curr_marble.next = nil
    @curr_marble = prev
    # p marble_at_cursor
    marble_at_cursor
  end

  def insert_after_cursor(marble)
    new_marble = Node.new(marble)
    new_marble.prev = @curr_marble
    @curr_marble.next.prev = new_marble
    new_marble.next = @curr_marble.next
    @curr_marble.next = new_marble
  end

  def to_s
    res = "[#{@head.marble}"
    curr_node = @head.next
    while curr_node != @head
      res += ", #{curr_node.marble}"
      curr_node = curr_node.next
    end
    res + ']'
  end
end

trials.each do |num_players, last_marble|
  circle = ListCircle.new
  scores = Array.new(num_players, 0)
  curr_player = 0

  (1..last_marble).each do |ith_marble|
    # p ith_marble
    if (ith_marble % 23).zero?
      scores[curr_player] += ith_marble
      circle.move_cursor(-6)
      scores[curr_player] += circle.delete_marble_at_cursor
      # circle.move_cursor(-1)
    else
      circle.move_cursor(2)
      circle.insert_after_cursor(ith_marble)
    end
    # puts circle
    curr_player = (curr_player + 1) % num_players
  end

  puts "Highest score: #{scores.max}"
end

puts
