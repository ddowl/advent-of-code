defmodule FFT do
  def apply(digit_list, _, 0), do: digit_list
  def apply(digit_list, f, n), do: FFT.apply(f.(digit_list), f, n - 1)

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

  def fast_phases(digit_list, n) do
    digit_list
    |> Enum.reverse()
    |> FFT.apply(fn l -> Enum.scan(l, 0, fn d, acc -> rem(d + acc, 10) end) end, n)
    |> Enum.reverse()
  end

  # If we're operating on the end of a signal, we're able to use a heuristic that
  # only applies to the end of the last digits of the matrix transformation:
  # The last digit of phase(n) is n, the second-to-last digit is the last digit plus the old second to-last digit, and so on.
  def fast_phase(digit_list) do
    # no `scanr`, so we have to reverse the list

    digit_list
    |> Enum.reverse()
    |> Enum.scan(0, fn d, acc -> rem(d + acc, 10) end)
    |> Enum.reverse()
  end
end

{:ok, signal} = File.read("input.txt")

# Part 1
digit_list =
  signal
  |> String.trim()
  |> String.graphemes()
  |> Enum.map(&String.to_integer/1)

phased_signal = digit_list |> FFT.apply(&FFT.phase/1, 100)
first_digits = Enum.take(phased_signal, 8) |> Enum.join() |> String.to_integer()
IO.inspect(first_digits)

# Part 2
# Since the 8-digit message offset is so deep into the signal, we're able to use a heuristic that
# only applies to the end of the last digits of the matrix transformation:
# The last digit of phase(n) is n, the second-to-last digit is the last digit plus the old second to-last digit, and so on.
message_offset = Enum.take(digit_list, 7) |> Enum.join() |> String.to_integer()
real_signal = digit_list |> List.duplicate(10000) |> List.flatten()
real_signal_end_chunk = Enum.drop(real_signal, message_offset)
phased_signal_chunk = FFT.fast_phases(real_signal_end_chunk, 100)
embedded_message = Enum.take(phased_signal_chunk, 8) |> Enum.join() |> String.to_integer()
IO.inspect(embedded_message)
