Code.require_file("../intcode.ex")

defmodule Droid do
  defmodule State do
    defstruct walls: MapSet.new(),
              floors: MapSet.new([{0, 0}]),
              pos: {0, 0},
              oxygen_tank_pos: nil,
              oxygen_tank_path_len: nil
  end

  def init(program) do
    parent = self()
    initial_state = %State{}
    droid_pid = spawn_link(fn -> ProcessIntcode.execute(program, parent) end)

    explorer_pid =
      spawn_link(fn ->
        explore_ship(parent, initial_state.pos, nil, MapSet.new(), 0)
        send(parent, :finished)
      end)

    loop(droid_pid, explorer_pid, initial_state)
  end

  def loop(droid_pid, explorer_pid, state) do
    receive do
      :finished ->
        state

      {:command, input_dir, steps_from_origin} ->
        send(droid_pid, {:input, input_dir})

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
        send(explorer_pid, {:command, status})

        new_state =
          case status do
            0 ->
              hit_wall(state, next_pos)

            1 ->
              next_droid_forward(state, state.pos, next_pos)

            2 ->
              state
              |> next_droid_forward(state.pos, next_pos)
              |> found_oxygen_tank(next_pos, steps_from_origin)
          end

        # IO.puts(known_floorplan(new_state))
        # IO.write("\n")

        # Process.sleep(10)
        loop(droid_pid, explorer_pid, new_state)
    end
  end

  def explore_ship(command_pid, pos, dir, seen, steps_from_origin) do
    seen = MapSet.put(seen, pos)
    adjacent_positions = find_adjacent_positions(command_pid, pos, steps_from_origin)

    seen =
      List.foldl(adjacent_positions, seen, fn {p, d}, acc ->
        if !MapSet.member?(acc, p) do
          command_droid(command_pid, d, steps_from_origin)
          explore_ship(command_pid, p, d, acc, steps_from_origin + 1)
        else
          seen
        end
      end)

    if !is_nil(dir) do
      command_droid(command_pid, opposite_direction(dir), steps_from_origin)
    end

    seen
  end

  defp find_adjacent_positions(command_pid, pos, steps_from_origin) do
    # try all directions! only use those that are not walls
    # not a fan of tracking positions in explorer and command

    [1, 2, 3, 4]
    |> Enum.map(fn dir -> {move_in_dir(pos, dir), dir} end)
    |> Enum.filter(fn {p, dir} ->
      status = command_droid(command_pid, dir, steps_from_origin)

      is_wall = status == 0

      if !is_wall do
        retreat_status = command_droid(command_pid, opposite_direction(dir), steps_from_origin)

        if retreat_status == 0 do
          raise "Can't move back to open floor???"
        end
      end

      !is_wall
    end)
  end

  defp command_droid(command_pid, dir, steps_from_origin) do
    send(command_pid, {:command, dir, steps_from_origin})

    receive do
      {:command, msg} -> msg
    end
  end

  defp hit_wall(state, wall), do: %{state | walls: MapSet.put(state.walls, wall)}

  defp next_droid_forward(state, prev_pos, curr_pos),
    do: %{state | floors: MapSet.put(state.floors, prev_pos), pos: curr_pos}

  defp found_oxygen_tank(state, pos, steps),
    do: %{state | oxygen_tank_pos: pos, oxygen_tank_path_len: steps}

  def move_in_dir({x, y}, 1), do: {x, y + 1}
  def move_in_dir({x, y}, 2), do: {x, y - 1}
  def move_in_dir({x, y}, 3), do: {x - 1, y}
  def move_in_dir({x, y}, 4), do: {x + 1, y}

  defp opposite_direction(1), do: 2
  defp opposite_direction(2), do: 1
  defp opposite_direction(3), do: 4
  defp opposite_direction(4), do: 3

  defp known_floorplan(%State{walls: walls, floors: floors, pos: pos, oxygen_tank_pos: otp}) do
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
          p == otp -> "O"
          MapSet.member?(floors, p) -> "."
          MapSet.member?(walls, p) -> "#"
          true -> " "
        end
      end)
      |> Enum.join()
    end)
    |> Enum.join("\n")
  end
end

defmodule Oxygen do
  def fill_ship_from_tank(floor_positions, tank_pos) do
    {_, max_step} = fill_ship(floor_positions, tank_pos, MapSet.new(), 0)
    max_step
  end

  # TODO: generalize DFS for Oxygen spread and Droid exploration
  defp fill_ship(floor_positions, curr_pos, seen, steps_from_origin) do
    seen = MapSet.put(seen, curr_pos)
    adjacent_positions = find_adjacent_positions(floor_positions, curr_pos)

    List.foldl(adjacent_positions, {seen, steps_from_origin}, fn p, {seen, steps} ->
      if !MapSet.member?(seen, p) do
        {seen_more, other_steps} = fill_ship(floor_positions, p, seen, steps_from_origin + 1)
        {seen_more, max(steps, other_steps)}
      else
        {seen, steps}
      end
    end)
  end

  defp find_adjacent_positions(floor_positions, curr_pos) do
    [1, 2, 3, 4]
    |> Enum.map(fn dir -> Droid.move_in_dir(curr_pos, dir) end)
    |> Enum.filter(fn p -> MapSet.member?(floor_positions, p) end)
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
ship_floorplan = Droid.init(droid_program)
IO.inspect(ship_floorplan)
IO.inspect(ship_floorplan.oxygen_tank_path_len)

# Part 2
# DFS max depth on floor graph, starting at oxygen tank
floors = ship_floorplan.floors
tank_pos = ship_floorplan.oxygen_tank_pos
IO.inspect(Oxygen.fill_ship_from_tank(floors, tank_pos))
