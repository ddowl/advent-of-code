defmodule Intcode do
  # Operations
  @halt_op 99
  @add_op 1
  @mult_op 2
  @read_op 3
  @write_op 4
  @jump_if_true_op 5
  @jump_if_false_op 6
  @less_than_op 7
  @equals_op 8

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

    case op do
      @halt_op ->
        int_array

      @add_op ->
        new_array = math_op(int_array, ip, modes, &+/2)
        execute(new_array, ip + 4)

      @mult_op ->
        new_array = math_op(int_array, ip, modes, &*/2)
        execute(new_array, ip + 4)

      @read_op ->
        read_pos = elem(int_array, ip + 1)
        read_val = IO.gets("Input: ") |> String.trim() |> String.to_integer()
        new_array = put_elem(int_array, read_pos, read_val)
        execute(new_array, ip + 2)

      @write_op ->
        write_val = get_arg(int_array, ip, 1, modes)
        IO.puts(write_val)
        execute(int_array, ip + 2)

      @jump_if_true_op ->
        next_ip = jump_test(int_array, ip, modes, fn x -> x != 0 end)
        execute(int_array, next_ip)

      @jump_if_false_op ->
        next_ip = jump_test(int_array, ip, modes, fn x -> x == 0 end)
        execute(int_array, next_ip)

      @less_than_op ->
        new_array = compare_op(int_array, ip, modes, &</2)
        execute(new_array, ip + 4)

      @equals_op ->
        new_array = compare_op(int_array, ip, modes, &==/2)
        execute(new_array, ip + 4)

      x ->
        raise "unknown op: #{x}"
    end
  end

  def put_noun_verb(int_array, noun, verb) do
    int_array |> put_elem(1, noun) |> put_elem(2, verb)
  end

  defp math_op(int_array, ip, modes, f) do
    {arg1, arg2, dest_pos} = get_bin_op_args(int_array, ip, modes)
    put_elem(int_array, dest_pos, f.(arg1, arg2))
  end

  defp compare_op(int_array, ip, modes, comp_fn) do
    {arg1, arg2, dest_pos} = get_bin_op_args(int_array, ip, modes)
    test_result = if comp_fn.(arg1, arg2), do: 1, else: 0
    put_elem(int_array, dest_pos, test_result)
  end

  defp jump_test(int_array, ip, modes, test_fn) do
    test_arg = get_arg(int_array, ip, 1, modes)
    jump_addr_arg = get_arg(int_array, ip, 2, modes)

    if test_fn.(test_arg) do
      jump_addr_arg
    else
      ip + 3
    end
  end

  defp get_bin_op_args(int_array, ip, modes) do
    arg1 = get_arg(int_array, ip, 1, modes)
    arg2 = get_arg(int_array, ip, 2, modes)
    dest_pos = elem(int_array, ip + 3)
    {arg1, arg2, dest_pos}
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

{:ok, intcode_str} = File.read("input.txt")

intcode_program =
  intcode_str
  |> String.trim()
  |> String.split(",")
  |> Enum.map(&String.to_integer/1)
  |> List.to_tuple()

IO.inspect(intcode_program)
Intcode.execute(intcode_program)
