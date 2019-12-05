defmodule PasswordChecker do
  def is_valid?(password) do
    adjacent_digits(password) && non_decreasing_digits(password)
  end

  def adjacent_digits(password) do
    password
    |> String.graphemes()
    |> Enum.chunk_every(2, 1, :discard)
    |> Enum.any?(fn [x, y] -> x == y end)
  end

  def non_decreasing_digits(password) do
    password
    |> String.graphemes()
    |> Enum.chunk_every(2, 1, :discard)
    |> Enum.all?(fn [x, y] -> x <= y end)
  end
end

# Part 1
# Strategy: Iterate over each number in the sequence and test each
# password fact (1) 2 adjacent digits are the same (2) digits never decrease
password_range = 156_218..652_527

num_valid_passwords =
  password_range
  |> Enum.map(&Integer.to_string/1)
  |> Enum.filter(&PasswordChecker.is_valid?/1)
  |> Enum.count()

IO.puts("Part 1: Number of valid passwords in range")
IO.inspect(num_valid_passwords)
