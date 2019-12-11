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

  def execute(int_array, inputs \\ []) do
    {halt_state_program, outputs} = execute(int_array, 0, inputs, [])
    outputs
  end

  def execute(int_array, ip, inputs, outputs) do
    instr = elem(int_array, ip)

    {op, modes} = extract_op_modes(instr)

    case op do
      @halt_op ->
        {int_array, outputs}

      @add_op ->
        new_array = math_op(int_array, ip, modes, &+/2)
        execute(new_array, ip + 4, inputs, outputs)

      @mult_op ->
        new_array = math_op(int_array, ip, modes, &*/2)
        execute(new_array, ip + 4, inputs, outputs)

      @read_op ->
        read_pos = elem(int_array, ip + 1)

        {read_val, remaining_inputs} =
          case inputs do
            [] ->
              {IO.gets("Input: ") |> String.trim() |> String.to_integer(), []}

            [x | xs] ->
              {x, xs}
          end

        new_array = put_elem(int_array, read_pos, read_val)
        execute(new_array, ip + 2, remaining_inputs, outputs)

      @write_op ->
        write_val = get_arg(int_array, ip, 1, modes)
        execute(int_array, ip + 2, inputs, [write_val | outputs])

      @jump_if_true_op ->
        next_ip = jump_test(int_array, ip, modes, fn x -> x != 0 end)
        execute(int_array, next_ip, inputs, outputs)

      @jump_if_false_op ->
        next_ip = jump_test(int_array, ip, modes, fn x -> x == 0 end)
        execute(int_array, next_ip, inputs, outputs)

      @less_than_op ->
        new_array = compare_op(int_array, ip, modes, &</2)
        execute(new_array, ip + 4, inputs, outputs)

      @equals_op ->
        new_array = compare_op(int_array, ip, modes, &==/2)
        execute(new_array, ip + 4, inputs, outputs)

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

  defp extract_op_modes(instr) do
    op = rem(instr, 100)

    modes =
      div(instr, 100)
      |> Integer.to_string()
      |> String.graphemes()
      |> List.foldr({%{}, 1}, fn d, {modes, arg_n} ->
        {Map.put(modes, arg_n, String.to_integer(d)), arg_n + 1}
      end)
      |> elem(0)

    {op, modes}
  end
end

defmodule Global do
  def permutations([]), do: [[]]

  def permutations(list),
    do: for(elem <- list, rest <- permutations(list -- [elem]), do: [elem | rest])

  def run_amps(program, [a, b, c, d, e]) do
    [a_res] = Intcode.execute(program, [a, 0])
    [b_res] = Intcode.execute(program, [b, a_res])
    [c_res] = Intcode.execute(program, [c, b_res])
    [d_res] = Intcode.execute(program, [d, c_res])
    [e_res] = Intcode.execute(program, [e, d_res])
    e_res
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

phase_settings = [0, 1, 2, 3, 4]
phase_setting_permutations = Global.permutations(phase_settings)

largest_output_signal =
  phase_settings
  |> Global.permutations()
  |> Enum.map(fn settings -> Global.run_amps(intcode_program, settings) end)
  |> Enum.max()

IO.inspect(largest_output_signal)
