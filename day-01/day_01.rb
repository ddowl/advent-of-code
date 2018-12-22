require 'set'

sum = File.readlines('input.txt').map(&:to_i).sum
puts sum

sums = Set.new()
running_sum = 0
# Is there a more efficient way to generate a repeating list on demand?
seq = File.readlines('input.txt').map(&:to_i) * 100000
seq.each do |num|
  running_sum += num
  if sums.include?(running_sum)
    puts running_sum
    break
  end
  sums.add running_sum
end
