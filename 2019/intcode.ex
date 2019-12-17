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
  @change_relative_base_op 9

  # Modes
  @position_mode 0
  @immediate_mode 1
  @relative_mode 2

  defmodule State do
    @enforce_keys [:memory, :ip, :relative_base]
    defstruct [:memory, ip: 0, relative_base: 0]
  end

  defmodule Memory do
    def get(memory, idx) do
      m = expand_memory(memory, idx)
      {m, elem(m, idx)}
    end

    def set(memory, idx, val) do
      m = expand_memory(memory, idx)
      put_elem(m, idx, val)
    end

    # Expand available memory to be at least size idxs if necessary
    # fill empty idxs with 0s
    defp expand_memory(m, new_size) do
      curr_size = tuple_size(m)

      if(curr_size <= new_size) do
        diff_size = new_size - curr_size + 1
        padded_zeros = List.duplicate(0, diff_size)

        (Tuple.to_list(m) ++ padded_zeros) |> List.to_tuple()
      else
        m
      end
    end
  end

  defmodule IoFns do
    @enforce_keys [:get_input, :put_output]
    defstruct [:get_input, :put_output]
  end

  def execute(int_array, get_input, put_output) do
    state = %State{memory: int_array, ip: 0, relative_base: 0}
    io = %IoFns{get_input: get_input, put_output: put_output}

    execute(state, io)
  end

  defp execute(state, io) do
    {m, instr} = Memory.get(state.memory, state.ip)
    state = %{state | memory: m}

    {op, modes} = extract_op_modes(instr)
    # IO.inspect({op, modes, state})

    case op do
      @halt_op ->
        state.memory

      @add_op ->
        m = math_op(state, modes, &+/2)
        execute(%{state | memory: m, ip: state.ip + 4}, io)

      @mult_op ->
        m = math_op(state, modes, &*/2)
        execute(%{state | memory: m, ip: state.ip + 4}, io)

      @read_op ->
        {m, read_pos} = get_arg_pos(state, 1, modes)
        input = io.get_input.()
        m = Memory.set(m, read_pos, input)
        execute(%{state | memory: m, ip: state.ip + 2}, io)

      @write_op ->
        {m, write_val} = get_arg(state, 1, modes)
        io.put_output.(write_val)
        execute(%{state | memory: m, ip: state.ip + 2}, io)

      @jump_if_true_op ->
        {m, next_ip} = jump_test(state, modes, fn x -> x != 0 end)
        execute(%{state | memory: m, ip: next_ip}, io)

      @jump_if_false_op ->
        {m, next_ip} = jump_test(state, modes, fn x -> x == 0 end)
        execute(%{state | memory: m, ip: next_ip}, io)

      @less_than_op ->
        m = compare_op(state, modes, &</2)
        execute(%{state | memory: m, ip: state.ip + 4}, io)

      @equals_op ->
        m = compare_op(state, modes, &==/2)
        execute(%{state | memory: m, ip: state.ip + 4}, io)

      @change_relative_base_op ->
        {m, base_offset} = get_arg(state, 1, modes)
        new_relative_base = state.relative_base + base_offset

        execute(
          %{state | memory: m, ip: state.ip + 2, relative_base: new_relative_base},
          io
        )

      x ->
        raise "unknown op: #{x}"
    end
  end

  def put_noun_verb(int_array, noun, verb) do
    int_array |> put_elem(1, noun) |> put_elem(2, verb)
  end

  defp math_op(state, modes, f) do
    {arg1, arg2, dest_pos, int_array} = get_bin_op_args(state, modes)

    Memory.set(int_array, dest_pos, f.(arg1, arg2))
  end

  defp compare_op(state, modes, comp_fn) do
    {arg1, arg2, dest_pos, int_array} = get_bin_op_args(state, modes)

    test_result = if comp_fn.(arg1, arg2), do: 1, else: 0
    Memory.set(int_array, dest_pos, test_result)
  end

  defp jump_test(state, modes, test_fn) do
    {m, test_arg} = get_arg(state, 1, modes)
    {m, jump_addr_arg} = get_arg(%{state | memory: m}, 2, modes)

    next_ip =
      if test_fn.(test_arg) do
        jump_addr_arg
      else
        state.ip + 3
      end

    {m, next_ip}
  end

  defp get_bin_op_args(state, modes) do
    {m, arg1} = get_arg(state, 1, modes)
    {m, arg2} = get_arg(%{state | memory: m}, 2, modes)
    {m, dest_pos} = get_arg_pos(%{state | memory: m}, 3, modes)
    {arg1, arg2, dest_pos, m}
  end

  defp get_arg(state, arg_n, modes) do
    {m, idx} = get_arg_pos(state, arg_n, modes)
    Memory.get(m, idx)
  end

  defp get_arg_pos(%State{memory: m, ip: ip, relative_base: rb}, arg_n, modes) do
    case Map.get(modes, arg_n, 0) do
      @position_mode ->
        Memory.get(m, ip + arg_n)

      # Parameters that an instruction writes to will _never be in immediate mode_
      @immediate_mode ->
        {m, ip + arg_n}

      @relative_mode ->
        {m, p} = Memory.get(m, ip + arg_n)
        {m, p + rb}
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

defmodule TtyIntcode do
  def execute(int_array, inputs \\ []) do
    {:ok, input_agent} = Agent.start_link(fn -> inputs end)
    {:ok, output_agent} = Agent.start_link(fn -> [] end)

    Intcode.execute(
      int_array,
      fn ->
        inputs = Agent.get(input_agent, & &1)

        case inputs do
          [] ->
            IO.gets("Input: ") |> String.trim() |> String.to_integer()

          [x | xs] ->
            Agent.update(input_agent, fn _ -> xs end)
            x
        end
      end,
      fn x ->
        Agent.update(output_agent, fn xs -> [x | xs] end)
      end
    )

    Agent.get(output_agent, & &1)
  end
end

defmodule ProcessIntcode do
  def execute(int_array, output_pid) do
    {:ok, output_agent} = Agent.start_link(fn -> [] end)

    Intcode.execute(
      int_array,
      fn ->
        receive do
          {:input, msg} -> msg
        end
      end,
      fn x ->
        Agent.update(output_agent, fn outputs -> [x | outputs] end)
        send(output_pid, {:output, x})
      end
    )

    Agent.get(output_agent, & &1)
  end
end
