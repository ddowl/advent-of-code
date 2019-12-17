Code.require_file("../intcode.ex")

{:ok, intcode_str} = File.read("input.txt")

intcode_program =
  intcode_str
  |> String.trim()
  |> String.split(",")
  |> Enum.map(&String.to_integer/1)
  |> List.to_tuple()

IO.inspect(intcode_program)

# Part 1
IO.inspect(TtyIntcode.execute(intcode_program, [1]) |> Enum.reverse())

# Part 2
IO.inspect(TtyIntcode.execute(intcode_program, [2]) |> Enum.reverse())
