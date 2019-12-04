defmodule Intcode do
  @halt 99
  @add 1
  @mult 2

  def execute(int_array) do
    elem(execute(int_array, 0), 0)
  end

  def execute(int_array, ip) do
    op = elem(int_array, ip)

    case op do
      @halt ->
        int_array

      @add ->
        new_array = run_op(int_array, ip, &+/2)
        execute(new_array, ip + 4)

      @mult ->
        new_array = run_op(int_array, ip, &*/2)
        execute(new_array, ip + 4)

      x ->
        raise "unknown op: #{x}"
    end
  end

  def put_noun_verb(int_array, noun, verb) do
    int_array |> put_elem(1, noun) |> put_elem(2, verb)
  end

  defp run_op(int_array, ip, f) do
    arg1_pos = elem(int_array, ip + 1)
    arg2_pos = elem(int_array, ip + 2)
    dest_pos = elem(int_array, ip + 3)

    arg1 = elem(int_array, arg1_pos)
    arg2 = elem(int_array, arg2_pos)

    put_elem(int_array, dest_pos, f.(arg1, arg2))
  end
end

{:ok, intcode_program} = File.read("input.txt")

int_array =
  intcode_program
  |> String.split(",", trim: true)
  |> Enum.map(fn s -> elem(Integer.parse(s), 0) end)
  |> List.to_tuple()

IO.inspect(int_array)

# Part 1: Before running the program,
# replace position 1 with the value 12 and
# replace position 2 with the value 2
reset_int_array = Intcode.put_noun_verb(int_array, 12, 2)

IO.inspect(Intcode.execute(reset_int_array))

# Part 2: Determine what pair of inputs
# produces the output 19690720.

goal = 19_690_720
bound = 0..100

for noun <- bound,
    verb <- bound do
  reset_int_array = Intcode.put_noun_verb(int_array, noun, verb)
  output = Intcode.execute(reset_int_array)

  if output == goal do
    IO.inspect({noun, verb})
    IO.inspect(100 * noun + verb)
  end
end
