defmodule Dungeon do
  defmodule Explorer do
    defstruct [
      :curr_key,
      :found_keys,
      :path,
      :total_distance
    ]
  end

  defmodule State do
    defstruct [
      :doors,
      :keys,
      :distances_between_keys,
      :doors_between_keys
    ]
  end

  defmodule Crawler do
    def all_keys_min_distance(explorer, dungeon) do
      {:ok, path_cache_pid} = Agent.start_link(fn -> %{} end)

      shortest_path_len = all_keys_min_distance(explorer, dungeon, path_cache_pid)

      Agent.stop(path_cache_pid)
      # final_cache = Agent.get(path_cache_pid, & &1)
      # all_keys = MapSet.new(Map.values(dungeon.keys))

      # final_cache
      # |> Enum.filter(fn {{_, keys_found}, _} -> keys_found == all_keys end)
      # |> Enum.map(fn {_, d} -> d end)
      # |> Enum.min()

      shortest_path_len
    end

    # Memoize min distance to path (location, keys_held)
    defp all_keys_min_distance(explorer, dungeon, path_cache_pid) do
      curr_key = explorer.curr_key
      found_keys = explorer.found_keys
      curr_cache = Agent.get(path_cache_pid, & &1)

      # IO.inspect("curr cache")
      # IO.inspect(curr_cache)
      total_distance = explorer.total_distance
      # IO.inspect("curr_key, found_keys, total distance")
      # IO.inspect({curr_key, found_keys, total_distance})

      case Map.get(curr_cache, {curr_key, found_keys}) do
        # if getting to this (position, key set) took longer than a cache'd path, no need to explore any more
        {cached_distance, _} when total_distance >= cached_distance ->
          # IO.inspect("pruned")
          # IO.inspect({curr_key, found_keys, total_distance, cached_distance})
          cached_distance

        _ ->
          # explore adjacent nodes
          case Dungeon.Crawler.reachable_keys(dungeon, curr_key, found_keys) do
            # If there's no more keys to look for, we're done!
            [] ->
              Agent.update(path_cache_pid, fn c ->
                Map.put(c, {curr_key, found_keys}, {total_distance, explorer.path})
              end)

              total_distance

            adj_keys ->
              # Otherwise we need to find the min distance to the remaining keys
              min_dist_to_curr =
                adj_keys
                |> Enum.map(fn {key, dist_to_key} ->
                  all_keys_min_distance(
                    %Dungeon.Explorer{
                      explorer
                      | curr_key: key,
                        found_keys: MapSet.put(found_keys, key),
                        path: explorer.path ++ [key],
                        total_distance: total_distance + dist_to_key
                    },
                    dungeon
                  )
                end)
                |> Enum.min()

              # cache this node with the least-distance path so far
              Agent.update(path_cache_pid, fn c ->
                Map.put(c, {curr_key, found_keys}, {min_dist_to_curr, explorer.path})
              end)

              min_dist_to_curr
          end
      end
    end

    def reachable_keys(
          %Dungeon.State{
            doors_between_keys: doors_bk,
            distances_between_keys: distance_bk,
            doors: doors,
            keys: keys
          },
          curr_key,
          found_keys
        ) do
      lost_keys =
        keys
        |> Map.keys()
        |> Enum.reject(fn k -> MapSet.member?(found_keys, k) end)

      opened_doors = found_keys |> Enum.map(fn k -> String.upcase(k) end) |> MapSet.new()

      reachable_lost_keys =
        lost_keys
        |> Enum.filter(fn k ->
          pair = MapSet.new([curr_key, k])
          remaining_doors_between = Map.get(doors_bk, pair) |> MapSet.difference(opened_doors)
          Enum.empty?(remaining_doors_between)
        end)

      reachable_lost_keys
      |> Enum.map(fn k -> {k, Map.get(distance_bk, MapSet.new([curr_key, k]))} end)
    end

    defp adjacent_open_spaces(open_spaces, {x, y}) do
      [{x + 1, y}, {x - 1, y}, {x, y + 1}, {x, y - 1}]
      |> Enum.filter(fn pos -> MapSet.member?(open_spaces, pos) end)
    end

    # TODO: consolidate BFS tracking logic of "distance_from" and "doors_between" into function params
    def distance_from(a, b, spaces) do
      distance_from(:queue.in({a, 0}, :queue.new()), b, spaces, MapSet.new([a]))
    end

    defp distance_from(queue, goal, spaces, seen) do
      case :queue.out(queue) do
        {:empty, _} ->
          # could not find a path
          nil

        {{:value, {pos, dist}}, queue} ->
          if pos == goal do
            # found the goal!
            dist
          else
            unseen_adjs =
              adjacent_open_spaces(spaces, pos)
              |> Enum.filter(fn adj -> !MapSet.member?(seen, adj) end)

            seen = MapSet.union(seen, MapSet.new(unseen_adjs))

            new_queue =
              Enum.reduce(unseen_adjs, queue, fn adj, q -> :queue.in({adj, dist + 1}, q) end)

            distance_from(new_queue, goal, spaces, seen)
          end
      end
    end

    def doors_between(a, b, spaces, doors) do
      doors_between(:queue.in({a, MapSet.new()}, :queue.new()), b, spaces, doors, MapSet.new([a]))
    end

    defp doors_between(queue, goal, spaces, doors, seen) do
      case :queue.out(queue) do
        {:empty, _} ->
          # could not find a path
          nil

        {{:value, {pos, doors_in_path}}, queue} ->
          if pos == goal do
            # found the goal!
            doors_in_path
          else
            unseen_adjs =
              adjacent_open_spaces(spaces, pos)
              |> Enum.filter(fn adj -> !MapSet.member?(seen, adj) end)

            seen = MapSet.union(seen, MapSet.new(unseen_adjs))

            new_queue =
              Enum.reduce(unseen_adjs, queue, fn adj, q ->
                updated_doors =
                  case Map.get(doors, adj) do
                    nil -> doors_in_path
                    sym -> MapSet.put(doors_in_path, sym)
                  end

                :queue.in({adj, updated_doors}, q)
              end)

            doors_between(new_queue, goal, spaces, doors, seen)
          end
      end
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

    {:ok, contents} = File.read("ex4.part1")

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
      |> Enum.into(%{}, fn {k, [v]} -> {k, v} end)

    starting_pos = dungeon_coords |> Map.get("@") |> hd

    # Part 1:
    # Precompute distances and list of doors between each pair of points
    keys_and_start = Map.merge(keys, %{"@" => starting_pos})
    keys_and_start_syms = Map.keys(keys_and_start)
    keys_and_start_coords = Map.values(keys_and_start)

    key_pairs = for i <- keys_and_start_syms, j <- keys_and_start_syms, i != j, i < j, do: {i, j}

    open_spaces_and_doors = MapSet.union(open_spaces, MapSet.new(Map.values(doors)))

    distances_between_keys =
      key_pairs
      |> Enum.map(fn {a, b} ->
        {MapSet.new([a, b]),
         Dungeon.Crawler.distance_from(
           Map.get(keys_and_start, a),
           Map.get(keys_and_start, b),
           open_spaces_and_doors
         )}
      end)
      |> Enum.into(%{})

    doors_between_keys =
      key_pairs
      |> Enum.map(fn {a, b} ->
        {MapSet.new([a, b]),
         Dungeon.Crawler.doors_between(
           Map.get(keys_and_start, a),
           Map.get(keys_and_start, b),
           open_spaces_and_doors,
           Enum.into(doors, %{}, fn {k, v} -> {v, k} end)
         )}
      end)
      |> Enum.into(%{})

    # Static state
    dungeon = %Dungeon.State{
      keys: keys,
      doors: doors,
      distances_between_keys: distances_between_keys,
      doors_between_keys: doors_between_keys
    }

    # For tracking during search
    explorer = %Dungeon.Explorer{
      curr_key: "@",
      found_keys: MapSet.new(["@"]),
      path: [],
      total_distance: 0
    }

    # IO.inspect(Dungeon.Crawler.reachable_keys(dungeon, explorer.curr_key, explorer.found_keys))
    min_dist = Dungeon.Crawler.all_keys_min_distance(explorer, dungeon)
    IO.inspect(min_dist)
  end
end

Main.main()
