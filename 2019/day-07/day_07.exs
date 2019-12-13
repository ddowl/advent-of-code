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

  def execute(int_array, get_input, put_output) do
    execute(int_array, 0, get_input, put_output)
  end

  def execute(int_array, ip, get_input, put_output) do
    instr = elem(int_array, ip)

    {op, modes} = extract_op_modes(instr)

    case op do
      @halt_op ->
        int_array

      @add_op ->
        new_array = math_op(int_array, ip, modes, &+/2)
        execute(new_array, ip + 4, get_input, put_output)

      @mult_op ->
        new_array = math_op(int_array, ip, modes, &*/2)
        execute(new_array, ip + 4, get_input, put_output)

      @read_op ->
        read_pos = elem(int_array, ip + 1)
        new_array = put_elem(int_array, read_pos, get_input.())
        execute(new_array, ip + 2, get_input, put_output)

      @write_op ->
        write_val = get_arg(int_array, ip, 1, modes)
        put_output.(write_val)
        execute(int_array, ip + 2, get_input, put_output)

      @jump_if_true_op ->
        next_ip = jump_test(int_array, ip, modes, fn x -> x != 0 end)
        execute(int_array, next_ip, get_input, put_output)

      @jump_if_false_op ->
        next_ip = jump_test(int_array, ip, modes, fn x -> x == 0 end)
        execute(int_array, next_ip, get_input, put_output)

      @less_than_op ->
        new_array = compare_op(int_array, ip, modes, &</2)
        execute(new_array, ip + 4, get_input, put_output)

      @equals_op ->
        new_array = compare_op(int_array, ip, modes, &==/2)
        execute(new_array, ip + 4, get_input, put_output)

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

defmodule TtyIntcode do
  def execute(int_array, inputs \\ []) do
    {:ok, input_agent} = Agent.start_link(fn -> inputs end)
    {:ok, output_agent} = Agent.start_link(fn -> [] end)

    Intcode.execute(
      int_array,
      0,
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
      0,
      fn ->
        receive do
          {:input, msg} -> msg
        end
      end,
      fn x ->
        Agent.update(output_agent, fn outputs -> [x | outputs] end)
        send(output_pid, {:input, x})
      end
    )

    Agent.get(output_agent, & &1)
  end
end

defmodule Amp do
  def execute(int_array, amp_name) do
    parent = self()

    spawn_link(fn ->
      pid =
        receive do
          {:output_pid, p} -> p
        end

      outputs = ProcessIntcode.execute(int_array, pid)
      send(parent, {:amp_halted, amp_name, outputs})
    end)
  end
end

defmodule Global do
  def permutations([]), do: [[]]

  def permutations(list),
    do: for(elem <- list, rest <- permutations(list -- [elem]), do: [elem | rest])

  def max_perm_transform(choices, f) do
    choices
    |> Global.permutations()
    |> Enum.map(f)
    |> Enum.max()
  end

  def run_amps_serial(program, [a, b, c, d, e], init_input \\ 0) do
    [a_res] = TtyIntcode.execute(program, [a, init_input])
    [b_res] = TtyIntcode.execute(program, [b, a_res])
    [c_res] = TtyIntcode.execute(program, [c, b_res])
    [d_res] = TtyIntcode.execute(program, [d, c_res])
    [e_res] = TtyIntcode.execute(program, [e, d_res])
    e_res
  end

  def run_amps_feedback(program, [a, b, c, d, e], init_input \\ 0) do
    # need to instatiate each process, then send output mailbox to each process to start
    a_pid = Amp.execute(program, :a)
    b_pid = Amp.execute(program, :b)
    c_pid = Amp.execute(program, :c)
    d_pid = Amp.execute(program, :d)
    e_pid = Amp.execute(program, :e)

    # connect program outputs in a cycle
    send(a_pid, {:output_pid, b_pid})
    send(b_pid, {:output_pid, c_pid})
    send(c_pid, {:output_pid, d_pid})
    send(d_pid, {:output_pid, e_pid})
    send(e_pid, {:output_pid, a_pid})

    # supply phase setting as first input
    send(a_pid, {:input, a})
    send(b_pid, {:input, b})
    send(c_pid, {:input, c})
    send(d_pid, {:input, d})
    send(e_pid, {:input, e})

    # kick off feedback loop by supplying second input to A
    send(a_pid, {:input, init_input})

    # last output signal from E is sent to thrusters
    receive do
      {:amp_halted, :e, [last_output | xs]} -> last_output
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

# Part 1
serial_phase_settings = [0, 1, 2, 3, 4]

largest_output_signal_serial =
  Global.max_perm_transform(serial_phase_settings, fn settings ->
    Global.run_amps_serial(intcode_program, settings)
  end)

IO.inspect(largest_output_signal_serial)

# Part 2
feedback_phase_settings = [5, 6, 7, 8, 9]

largest_output_signal_feedback =
  Global.max_perm_transform(feedback_phase_settings, fn settings ->
    Global.run_amps_feedback(intcode_program, settings)
  end)

IO.inspect(largest_output_signal_feedback)
