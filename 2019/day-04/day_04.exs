defmodule PasswordChecker do
  def adjacent_digits(password) do
    password
    |> String.graphemes()
    |> Enum.chunk_every(2, 1, :discard)
    |> Enum.any?(fn [x, y] -> x == y end)
  end

  def contains_digit_pair(password) do
    password
    |> String.graphemes()
    |> Enum.chunk_by(& &1)
    |> Enum.map(&Enum.count/1)
    |> Enum.member?(2)
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
  |> Enum.filter(fn password ->
    PasswordChecker.adjacent_digits(password) && PasswordChecker.non_decreasing_digits(password)
  end)
  |> Enum.count()

IO.puts("Part 1: Number of valid passwords in range, have adjacent digits, non-decreasing")
IO.inspect(num_valid_passwords)

# Part 2
num_valid_passwords =
  password_range
  |> Enum.map(&Integer.to_string/1)
  |> Enum.filter(fn password ->
    PasswordChecker.contains_digit_pair(password) &&
      PasswordChecker.non_decreasing_digits(password)
  end)
  |> Enum.count()

IO.puts("Part 2: Number of valid passwords in range, have digit pairs, non-decreasing")
IO.inspect(num_valid_passwords)
