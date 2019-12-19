Code.require_file("../intcode.ex")

{:ok, intcode_str} = File.read("input.txt")

arcade_program =
  intcode_str
  |> String.trim()
  |> String.split(",")
  |> Enum.map(&String.to_integer/1)
  |> List.to_tuple()

IO.inspect(arcade_program)

# Part 1
arcade_screen = TtyIntcode.execute(arcade_program) |> Enum.reverse()

tiles =
  arcade_screen
  |> Enum.chunk_every(3)
  |> List.foldl(%{}, fn [x, y, tile_id], acc ->
    tile_type =
      case tile_id do
        0 -> :empty
        1 -> :wall
        2 -> :block
        3 -> :paddle
        4 -> :ball
      end

    positions_with_type = Map.get(acc, tile_type, [])
    Map.put(acc, tile_type, [{x, y} | positions_with_type])
  end)

IO.inspect(Map.get(tiles, :block) |> Enum.count())
