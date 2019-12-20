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
    # Send input instruction

    # Receive status
    status =
      receive do
        {:output, msg} -> msg
      after
        1000 -> nil
      end

    IO.inspect(status)

    if is_nil(status) do
      state
    else
      loop(droid_pid, state)
    end
  end

  def known_floorplan(%State{walls: walls, floors: floors, pos: pos}) do
    known_positions = MapSet.union(walls, floors)

    xs = Enum.map(known_positions, fn {x, _} -> x end)
    ys = Enum.map(known_positions, fn {_, y} -> y end)

    min_x = Enum.min(xs)
    max_x = Enum.max(xs)
    min_y = Enum.min(ys)
    max_y = Enum.max(ys)

    Enum.map(min_y..max_y, fn y ->
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
Droid.init(droid_program)
