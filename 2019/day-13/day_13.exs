Code.require_file("../intcode.ex")

defmodule Arcade do
  def screen(positions_to_tiles) do
    positions_to_tiles
    |> Enum.sort()
    |> Enum.group_by(fn {{_, y}, _} -> y end)
    |> Enum.map(fn {_y, x_positions} ->
      x_positions |> Enum.map(fn {_p, tile_id} -> tile_str(tile_id) end) |> Enum.join()
    end)
    |> Enum.join("\n")
  end

  def tile_str(id) do
    case id do
      0 -> " "
      1 -> "#"
      2 -> "="
      3 -> "_"
      4 -> "o"
    end
  end
end

{:ok, intcode_str} = File.read("input.txt")

arcade_program =
  intcode_str
  |> String.trim()
  |> String.split(",")
  |> Enum.map(&String.to_integer/1)
  |> List.to_tuple()

IO.inspect(arcade_program)

# Part 1
arcade_output = TtyIntcode.execute(arcade_program) |> Enum.reverse()

tiles_to_positions =
  arcade_output
  |> Enum.chunk_every(3)
  |> List.foldl(%{}, fn [x, y, tile_id], acc ->
    positions_with_type = Map.get(acc, tile_id, [])
    Map.put(acc, tile_id, [{x, y} | positions_with_type])
  end)

IO.inspect(Map.get(tiles_to_positions, 2) |> Enum.count())

# Part 2
fixed_arcade_program = put_elem(arcade_program, 0, 2)

# verifying output contains all spaces in grid
positions_to_tiles =
  arcade_output
  |> Enum.chunk_every(3)
  |> List.foldl(%{}, fn [x, y, tile_id], acc ->
    Map.put(acc, {x, y}, tile_id)
  end)

IO.puts(Arcade.screen(positions_to_tiles))
