# Store each generation of pots in a an array the with some empty pots buffering the left/rightmost plotted plant.
# Keep a variable to store the real index 0, so we can sum up the potted indices at the end.

input_filename = 'example_input.txt'
initial_state_str = File.read(input_filename).split(' ')[2]
p initial_state_str

RULES = File.readlines(input_filename).map do |line|
  match = line.scan(/([.#]+) => #/).first
  match.first if match
end.reject(&:nil?)
p RULES
RULE_LEN = RULES.first.length

class Pots
  def initialize(state_str, zero_idx)
    @pots = state_str
    p @pots
    first_plant_idx = @pots.index('#')
    if first_plant_idx < 4
      num_buffer_pots = 4 - first_plant_idx
      @pots = '.' * num_buffer_pots + @pots
      @zero_idx = zero_idx + num_buffer_pots
    end

    last_plant_idx = @pots.rindex('#')
    if last_plant_idx < @pots.length - 4
      num_buffer_pots = @pots.length - 4 - last_plant_idx
      @pots += '.' * num_buffer_pots
    end

    p first_plant_idx
    p last_plant_idx
    p @pots.length
  end

  def next_gen
    next_state_str = (2...@pots.length - 2).map do |idx|
      region = @pots[idx - 2..idx + 2]
      RULES.include?(region) ? '#' : '.'
    end.join
    Pots.new(next_state_str, @zero_idx - 2)
  end

  def index_sum
    @pots
      .chars
      .each_with_index.map { |pot, idx| [pot, idx - @zero_idx] }
      .select { |pot, _| pot == '#' }
      .map { |_, idx| idx }
      .sum
  end
end

pots = Pots.new(initial_state_str, 0)
# 50_000_000_000.times do
20.times do
  pots = pots.next_gen
end
p pots
p pots.index_sum

puts
