def has_letter_repeat?(id)
  has_n_dups?(id, 2)
end

def has_letter_threepeat?(id)
  has_n_dups?(id, 3)
end

def has_n_dups?(id, n)
  id.chars.group_by(&:itself).values.map(&:length).include?(n)
end

num_repeats = File.readlines('input.txt').count { |id| has_letter_repeat?(id) }
num_threepeats = File.readlines('input.txt').count { |id| has_letter_threepeat?(id) }
puts num_repeats * num_threepeats


def differ_by_one(a, b)
  a.chars.zip(b.chars).count { |x, y| x != y } == 1
end

def same_chars(a, b)
  a.chars.zip(b.chars).select { |x, y| x == y }.map(&:first).join
end

File.readlines('input.txt').each do |id_a|
  File.readlines('input.txt').each do |id_b|
    if differ_by_one(id_a, id_b)
      puts same_chars(id_a, id_b)
      exit
    end
  end
end