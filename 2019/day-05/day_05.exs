defmodule Intcode do
  # Operations
  @halt_op 99
  @add_op 1
  @mult_op 2
  @read_op 3
  @write_op 4

  # Modes
  @position_mode 0
  @immediate_mode 1

  def execute(int_array) do
    execute(int_array, 0)
  end

  def execute(int_array, ip) do
    instr = elem(int_array, ip)

    op = rem(instr, 100)

    modes =
      div(instr, 100)
      |> Integer.to_string()
      |> String.graphemes()
      |> List.foldr({%{}, 1}, fn d, {modes, arg_n} ->
        {Map.put(modes, arg_n, String.to_integer(d)), arg_n + 1}
      end)
      |> elem(0)

    # IO.inspect({instr, modes})

    case op do
      @halt_op ->
        int_array

      @add_op ->
        new_array = run_bin_op(int_array, ip, modes, &+/2)
        execute(new_array, ip + 4)

      @mult_op ->
        new_array = run_bin_op(int_array, ip, modes, &*/2)
        execute(new_array, ip + 4)

      @read_op ->
        read_pos = elem(int_array, ip + 1)
        read_val = IO.gets("Input: ") |> String.trim() |> String.to_integer()
        new_array = put_elem(int_array, read_pos, read_val)
        execute(new_array, ip + 2)

      @write_op ->
        write_pos = elem(int_array, ip + 1)
        IO.puts(elem(int_array, write_pos))
        execute(int_array, ip + 2)

      x ->
        raise "unknown op: #{x}"
    end
  end

  def put_noun_verb(int_array, noun, verb) do
    int_array |> put_elem(1, noun) |> put_elem(2, verb)
  end

  defp run_bin_op(int_array, ip, modes, f) do
    arg1 = get_arg(int_array, ip, 1, modes)
    arg2 = get_arg(int_array, ip, 2, modes)
    dest_pos = elem(int_array, ip + 3)

    put_elem(int_array, dest_pos, f.(arg1, arg2))
  end

  defp get_arg(int_array, ip, arg_n, modes) do
    if Map.get(modes, arg_n, 0) == @position_mode do
      argn_pos = elem(int_array, ip + arg_n)
      elem(int_array, argn_pos)
    else
      elem(int_array, ip + arg_n)
    end
  end
end

# Part 1: Diagnostic code
{:ok, intcode_program} = File.read("input.txt")

int_array =
  intcode_program
  |> String.split(",", trim: true)
  |> Enum.map(fn s -> elem(Integer.parse(s), 0) end)
  |> List.to_tuple()

IO.inspect(int_array)
Intcode.execute(int_array)
