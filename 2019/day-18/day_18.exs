defmodule Dungeon do
  defmodule State do
    defstruct [:curr_pos, :open_spaces, :doors, :keys, :path, :total_distance]
  end

  defmodule Crawler do
    def min_distance_to_collect_all_keys(dungeon) do
      {:ok, path_cache_pid} = Agent.start_link(fn -> %{} end)
      {:ok, reachable_key_cache_pid} = Agent.start_link(fn -> %{} end)

      shortest_path_len =
        min_dists_to_all_key_paths(dungeon, path_cache_pid, reachable_key_cache_pid)

      Agent.stop(path_cache_pid)
      Agent.stop(reachable_key_cache_pid)
      # final_cache = Agent.get(path_cache_pid, & &1)
      # all_keys = MapSet.new(Map.values(dungeon.keys))

      # final_cache
      # |> Enum.filter(fn {{_, keys_found}, _} -> keys_found == all_keys end)
      # |> Enum.map(fn {_, d} -> d end)
      # |> Enum.min()

      shortest_path_len
    end

    # Memoize min distance to path (location, keys_held)
    defp min_dists_to_all_key_paths(dungeon, path_cache_pid, reachable_key_cache_pid) do
      curr_pos = dungeon.curr_pos
      keys_found = MapSet.new(dungeon.path)
      curr_cache = Agent.get(path_cache_pid, & &1)

      # IO.inspect("curr cache")
      # IO.inspect(curr_cache)
      total_distance = dungeon.total_distance
      # IO.inspect("curr pos, keys found, total distance, cache")
      # IO.inspect({curr_pos, keys_found, total_distance, curr_cache})

      case Map.get(curr_cache, {curr_pos, keys_found}) do
        # if getting to this (position, key set) took longer than a cache'd path, no need to explore any more
        {cached_distance, _} when total_distance >= cached_distance ->
          # IO.inspect("pruned")
          # IO.inspect({curr_pos, keys_found, total_distance, cached_distance})
          nil

        _ ->
          # explore adjacent nodes
          case Dungeon.Crawler.reachable_keys(dungeon, reachable_key_cache_pid) do
            # If there's no more keys to look for, we're done!
            [] ->
              Agent.update(path_cache_pid, fn c ->
                Map.put(c, {curr_pos, keys_found}, {total_distance, dungeon.path})
              end)

              total_distance

            adj_keys ->
              # Otherwise we need to find the min distance to the remaining keys
              min_dist_to_curr =
                adj_keys
                |> Enum.map(fn {key, _, dungeon_at_key} ->
                  min_dists_to_all_key_paths(
                    dungeon_at_key,
                    path_cache_pid,
                    reachable_key_cache_pid
                  )
                end)
                |> Enum.min()

              # cache this node with the least-distance path so far
              Agent.update(path_cache_pid, fn c ->
                Map.put(c, {curr_pos, keys_found}, {min_dist_to_curr, dungeon.path})
              end)

              min_dist_to_curr
          end
      end
    end

    def reachable_keys(dungeon, cache_pid) do
      case Agent.get(cache_pid, fn cache -> Map.get(cache, dungeon) end) do
        nil ->
          keys =
            reachable_keys(dungeon, dungeon.curr_pos, MapSet.new(), 0, MapSet.new())
            |> List.flatten()

          Agent.update(cache_pid, fn cache -> Map.put(cache, dungeon, keys) end)
          keys

        keys ->
          keys
      end
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
            doors: Map.delete(dungeon.doors, corresponding_door),
            path: dungeon.path ++ [found_key],
            total_distance: dungeon.total_distance + distance_from_start
          }

          {found_key, distance_from_start, new_dungeon}
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

    {:ok, contents} = File.read("ex5.part1")

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
      keys: keys,
      path: [],
      total_distance: 0
    }

    IO.inspect(dungeon)

    # Part 1:
    # min_dist = min_distance_to_collect_all_keys(:queue.in({dungeon, 0, ["@"]}, :queue.new()))
    min_dist = Dungeon.Crawler.min_distance_to_collect_all_keys(dungeon)
    IO.inspect(min_dist)
  end
end

Main.main()
