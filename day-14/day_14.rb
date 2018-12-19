PUZZLE_INPUT = "880751"
puts "PUZZLE_INPUT: #{PUZZLE_INPUT}"

class RecipeSim
  attr_reader :scoreboard

  def initialize
    reset_state
  end

  def reset_state
    @scoreboard = Array.new(10_000_000)  # preallocate array so we don't have to concat every time
    @scoreboard[0] = 3
    @scoreboard[1] = 7
    @end_of_scoreboard_idx = 2
    @elf_positions = [0, 1]
  end

  def add_new_recipes_to_scoreboard
    sum_recipe_score = @scoreboard[@elf_positions[0]] + @scoreboard[@elf_positions[1]]
    new_recipes = sum_recipe_score.to_s.chars.map(&:to_i)
    new_recipes.each do |recipe|
      @scoreboard[@end_of_scoreboard_idx] = recipe
      @end_of_scoreboard_idx += 1
    end
  end

  def update_elf_positions
    @elf_positions.each_with_index do |pos, i|
      new_pos_offset = @scoreboard[pos] + 1
      new_pos = (pos + new_pos_offset) % size
      @elf_positions[i] = new_pos
    end
  end

  def tick
    add_new_recipes_to_scoreboard
    update_elf_positions
  end

  def size
    @end_of_scoreboard_idx
  end

  def last(n)
    ((size - n)...size).map { |idx| @scoreboard[idx] }
  end
end


def part1
  goal_scoreboard_size = PUZZLE_INPUT.to_i + 10

  sim = RecipeSim.new()
  until sim.size >= goal_scoreboard_size do
    sim.tick
  end
  sim.last(10).join
end

def part2
  sim = RecipeSim.new

  2.times do
    sim.tick
  end

  loop do
    sim.tick
    last_digits = sim.last(PUZZLE_INPUT.size + 1)
    opt1 = last_digits[0..-2].join
    opt2 = last_digits[1..-1].join
    if opt1 == PUZZLE_INPUT
      return sim.size - (PUZZLE_INPUT.size + 1)
    elsif opt2 == PUZZLE_INPUT
      return sim.size - PUZZLE_INPUT.size
    end
  end
end


puts "part1: #{part1}"

# Part 2
# Find the number of recipies to the left of the first occurence of PUZZLE_INPUT on the scoreboard
puts "part2: #{part2}"

puts