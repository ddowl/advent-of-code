polymer = File.open('input.txt') { |f| f.readline }.strip

# repeat process until polymer can't be reduced anymore:
# walk through string char by char
# if the current and next char are polar units, remove them and continue

# Monkeypatch String class for useful functions
class String
  def upper?
    match(/[[:upper:]]/)
  end

  def lower?
    match(/[[:lower:]]/)
  end
end

def polar_opposites?(a, b)
  (a.downcase == b.downcase) &&
    ((a.upper? && b.lower?) ||
      (a.lower? && b.upper?))
end

# returns the index of the first unit of a polar opposite
# otherwise, returns nil
def polar_opposite_search(polymer_units)
  polymer_units.each_with_index do |curr_char, i|
    break if polymer_units.length - 1 == i # can't look at the next char if we're on the last char

    next_char = polymer_units[i + 1]
    return "#{curr_char}#{next_char}" if polar_opposites?(curr_char, next_char)
  end
  nil
end

def react(polymer)
  units = polymer.chars
  polar_units = polar_opposite_search(units)
  until polar_units.nil?
    units = units.join.gsub(polar_units, '').chars
    polar_units = polar_opposite_search(units)
  end
  units.join
end


# Part 1
reacted_polymer = react(polymer)
puts reacted_polymer.size
puts

# Part 2
puts ('a'..'z')
       .map { |c| reacted_polymer.gsub(/#{c}|#{c.upcase}/, '') }
       .reject { |modified_polymer| modified_polymer.size == reacted_polymer.size }
       .map { |modified_polymer| react(modified_polymer).size }
       .min

puts
