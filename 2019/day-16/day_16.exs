defmodule FlawedFrequencyTransmission do
  def phases(digit_list, 0), do: digit_list
  def phases(digit_list, n), do: phases(phase(digit_list), n - 1)

  def phase(digit_list) do
    num_digits = length(digit_list)

    Enum.map(0..(num_digits - 1), fn i ->
      ith_pattern = pattern(i) |> Enum.take(num_digits)

      List.zip([digit_list, ith_pattern])
      |> Enum.map(fn {d, p} -> d * p end)
      |> Enum.sum()
      |> rem(10)
      |> abs()
    end)
  end

  def pattern(n) do
    [0, 1, 0, -1]
    |> Stream.cycle()
    |> Stream.flat_map(fn i ->
      List.duplicate(i, n + 1)
    end)
    |> Stream.drop(1)
  end
end

{:ok, signal} = File.read("input.txt")

# Part 1
digit_list =
  signal
  |> String.trim()
  |> String.graphemes()
  |> Enum.map(&String.to_integer/1)

IO.inspect(FlawedFrequencyTransmission.phases(digit_list, 100) |> Enum.join())
