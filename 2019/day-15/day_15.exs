Code.require_file("../intcode.ex")

defmodule Droid do
  defmodule State do
    defstruct walls: MapSet.new(), floors: MapSet.new([{0, 0}]), pos: {0, 0}
  end

  def init(program) do
    parent = self()
    droid_pid = spawn_link(fn -> ProcessIntcode.execute(program, parent) end)
    loop(droid_pid, %State{})
  end

  def loop(droid_pid, state) do
    IO.puts(known_floorplan(state))
    IO.write("\n")

    input_dir = 1

    # Send input instruction
    send(droid_pid, {:input, input_dir})

    # Receive status
    status =
      receive do
        {:output, msg} -> msg
      after
        1000 -> nil
      end

    if is_nil(status) do
      raise "Droid timeout: waiting for response"
    end

    next_pos = move_in_dir(state.pos, input_dir)

    if status == 2 do
      move_droid_forward(state, state.pos, next_pos)
    else
      new_state =
        case status do
          0 -> hit_wall(state, next_pos)
          1 -> move_droid_forward(state, state.pos, next_pos)
        end

      Process.sleep(500)
      loop(droid_pid, new_state)
    end
  end

  defp hit_wall(state, wall), do: %{state | walls: MapSet.put(state.walls, wall)}

  defp move_droid_forward(state, prev_pos, curr_pos),
    do: %{state | floors: MapSet.put(state.floors, prev_pos), pos: curr_pos}

  defp move_in_dir({x, y}, dir) do
    case dir do
      1 -> {x, y + 1}
      2 -> {x, y - 1}
      3 -> {x - 1, y}
      4 -> {x + 1, y}
    end
  end

  defp known_floorplan(%State{walls: walls, floors: floors, pos: pos}) do
    known_positions = MapSet.union(walls, MapSet.put(floors, pos))

    xs = Enum.map(known_positions, fn {x, _} -> x end)
    ys = Enum.map(known_positions, fn {_, y} -> y end)

    min_x = Enum.min(xs)
    max_x = Enum.max(xs)
    min_y = Enum.min(ys)
    max_y = Enum.max(ys)

    Enum.map(max_y..min_y, fn y ->
      Enum.map(min_x..max_x, fn x ->
        p = {x, y}

        cond do
          p == pos -> "D"
          MapSet.member?(floors, p) -> "."
          MapSet.member?(walls, p) -> "#"
        end
      end)
      |> Enum.join()
    end)
    |> Enum.join("\n")
  end
end

{:ok, intcode_str} = File.read("input.txt")

droid_program =
  intcode_str
  |> String.trim()
  |> String.split(",")
  |> Enum.map(&String.to_integer/1)
  |> List.to_tuple()

IO.inspect(droid_program)

# Part 1
IO.inspect(Droid.init(droid_program))
