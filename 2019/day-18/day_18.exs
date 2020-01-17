defmodule Dungeon do
  defmodule State do
    defstruct [:curr_pos, :open_spaces, :doors, :keys]
  end

  defmodule Crawler do
    def reachable_keys(dungeon) do
      reachable_keys(dungeon, dungeon.curr_pos, MapSet.new(), 0, MapSet.new())
      |> List.flatten()
    end

    defp reachable_keys(dungeon, curr_pos, seen, distance_from_start, reached_keys) do
      # label current pos as seen
      seen = MapSet.put(seen, curr_pos)

      case Map.get(dungeon.keys, curr_pos) do
        nil ->
          adjacent_open_spaces(dungeon, curr_pos)
          |> Enum.filter(fn adj -> !MapSet.member?(seen, adj) end)
          |> Enum.map(fn adj ->
            reachable_keys(dungeon, adj, seen, distance_from_start + 1, reached_keys)
          end)

        found_key ->
          corresponding_door = String.upcase(found_key)
          door_pos = Map.get(dungeon.doors, corresponding_door)

          new_dungeon = %Dungeon.State{
            curr_pos: curr_pos,
            open_spaces: MapSet.put(dungeon.open_spaces, door_pos),
            keys: Map.delete(dungeon.keys, curr_pos),
            doors: Map.delete(dungeon.doors, corresponding_door)
          }

          {found_key, curr_pos, distance_from_start, new_dungeon}
      end
    end

    defp adjacent_open_spaces(dungeon, {x, y}) do
      [{x + 1, y}, {x - 1, y}, {x, y + 1}, {x, y - 1}]
      |> Enum.filter(fn pos -> MapSet.member?(dungeon.open_spaces, pos) end)
    end
  end
end

# Main module needed to use structs defined in same .exs file
defmodule Main do
  def min_distance_to_collect_all_keys(dungeon) do
    # Figure out all of the keys you can reach from your current position.
    # Try collecting them in different orders, summing the total distance traveled.
    # Return the end state that has the largest distance traveled
    min_distance_to_collect_all_keys(dungeon, 0)
  end

  defp min_distance_to_collect_all_keys(dungeon, curr_distance) do
    case Dungeon.Crawler.reachable_keys(dungeon) do
      [] ->
        # No more keys to collect, return distance traveled
        curr_distance

      found_keys ->
        # Otherwise, choose possible paths, and take the min distance
        found_keys
        |> Enum.map(fn {_, _, dist, new_dungeon} ->
          min_distance_to_collect_all_keys(new_dungeon, dist + curr_distance)
        end)
        |> Enum.min()
    end
  end

  def main do
    # Puzzle input today represents a map (dungeon) we ("@") need to crawl in order to
    # collect keys (lowercase letters) and open doors (corresponding uppercase letters)
    # constrained by walls ("#"). The goal is to determine the shortest distance to
    # collect all of the keys.
    #
    # A hint from the prompt:
    #   Now, you have a choice between keys d and e. While key e is closer,
    #   collecting it now would be slower in the long run than collecting key d
    #   first, so that's the best choice...
    #
    # This seems to imply that there will be some path exploration/backtracking in order
    # to explore valid paths and pick the shortest.

    {:ok, contents} = File.read("ex1.part1")

    dungeon_str =
      contents
      |> String.split("\n")
      |> Enum.map(fn line ->
        String.split(line, "", trim: true)
        |> List.to_tuple()
      end)
      |> List.to_tuple()

    rows = tuple_size(dungeon_str)
    cols = tuple_size(elem(dungeon_str, 0))

    dungeon_coords =
      Enum.flat_map(
        0..(rows - 1),
        fn row ->
          Enum.map(0..(cols - 1), fn col ->
            {elem(dungeon_str, row) |> elem(col), {row, col}}
          end)
        end
      )
      |> Enum.reduce(%{}, fn {sym, coord}, acc ->
        l = Map.get(acc, sym, [])
        Map.put(acc, sym, [coord | l])
      end)

    # Includes open floor, yourself, and keys
    # Excludes doors and walls
    open_spaces =
      dungeon_coords
      |> Enum.filter(fn {sym, _} ->
        sym == "." || sym == "@" || String.match?(sym, ~r/[[:lower:]]/)
      end)
      |> Enum.map(fn {_, l} -> l end)
      |> List.flatten()
      |> MapSet.new()

    doors =
      dungeon_coords
      |> Enum.filter(fn {sym, _} ->
        String.match?(sym, ~r/[[:upper:]]/)
      end)
      |> Enum.into(%{}, fn {k, [v]} -> {k, v} end)

    keys =
      dungeon_coords
      |> Enum.filter(fn {sym, _} ->
        String.match?(sym, ~r/[[:lower:]]/)
      end)
      |> Enum.into(%{}, fn {k, [v]} -> {v, k} end)

    starting_pos = dungeon_coords |> Map.get("@") |> hd

    dungeon = %Dungeon.State{
      curr_pos: starting_pos,
      open_spaces: open_spaces,
      doors: doors,
      keys: keys
    }

    IO.inspect(dungeon)

    # Part 1:
    min_dist = min_distance_to_collect_all_keys(dungeon)
    IO.inspect(min_dist)
  end
end

Main.main()
