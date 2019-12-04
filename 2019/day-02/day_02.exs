defmodule Intcode do
  @halt 99
  @add 1
  @mult 2

  def execute(int_array, curr_pos) do
    op = elem(int_array, curr_pos)

    case op do
      @halt ->
        int_array

      @add ->
        new_array = run_op(int_array, curr_pos, &+/2)
        execute(new_array, curr_pos + 4)

      @mult ->
        new_array = run_op(int_array, curr_pos, &*/2)
        execute(new_array, curr_pos + 4)

      x ->
        raise "unknown op: #{x}"
    end
  end

  defp run_op(int_array, curr_pos, f) do
    arg1_pos = elem(int_array, curr_pos + 1)
    arg2_pos = elem(int_array, curr_pos + 2)
    dest_pos = elem(int_array, curr_pos + 3)

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

# Before running the program,
# replace position 1 with the value 12 and
# replace position 2 with the value 2
int_array = put_elem(int_array, 1, 12)
int_array = put_elem(int_array, 2, 2)

IO.inspect(Intcode.execute(int_array, 0))
