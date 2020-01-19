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
    def all_keys_min_distance_dijkstras(adj_list_graph, source_node, key_set) do
      node_collected_all_keys? = fn {_, found_keys} -> MapSet.equal?(found_keys, key_set) end

      {target_node, dist, _prev} =
        all_keys_min_distance_dijkstras(
          adj_list_graph,
          MapSet.new(Map.keys(adj_list_graph)),
          node_collected_all_keys?,
          %{source_node => 0},
          %{}
        )

      case target_node do
        nil -> raise "Exhausted Dijkstra search. We can recover from this, but it's unexpected"
        n -> Map.get(dist, n)
      end
    end

    defp all_keys_min_distance_dijkstras(graph, unknown_vertices, target_fn, dist, prev) do
      if Enum.empty?(unknown_vertices) do
        # traversed entire graph
        {nil, dist, prev}
      else
        {u, dist_u} =
          dist
          |> Map.take(MapSet.to_list(unknown_vertices))
          |> Enum.min_by(fn {_, v} -> v end)

        unknown_vertices = MapSet.delete(unknown_vertices, u)

        if target_fn.(u) do
          {u, dist, prev}
        else
          {dist, prev} =
            Dungeon.Crawler.adjacent_nodes(graph, u)
            |> Enum.reduce({dist, prev}, fn {v, dist_u_to_v}, {dist, prev} ->
              alt = dist_u + dist_u_to_v

              if alt < Map.get(dist, v) do
                {Map.put(dist, v, alt), Map.put(prev, v, u)}
              else
                {dist, prev}
              end
            end)

          all_keys_min_distance_dijkstras(graph, unknown_vertices, target_fn, dist, prev)
        end
      end
    end

    defp query_cache_loop(cache_pid) do
      IO.inspect({"cache size: ", Agent.get(cache_pid, fn c -> Enum.count(Map.keys(c)) end)})
      Process.sleep(1000)
      query_cache_loop(cache_pid)
    end

    def all_keys_min_distance_dp(graph, source_node, key_set) do
      {:ok, path_cache_pid} = Agent.start_link(fn -> %{} end)
      spawn_link(fn -> query_cache_loop(path_cache_pid) end)

      shortest_path_len = all_keys_min_distance_dp(graph, source_node, 0, key_set, path_cache_pid)

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
    defp all_keys_min_distance_dp(graph, curr_node, distance, key_set, cache_pid) do
      if MapSet.equal?(elem(curr_node, 1), key_set) do
        0
      else
        case Agent.get(cache_pid, fn c -> Map.get(c, curr_node) end) do
          nil ->
            # explore adjacent nodes
            case Dungeon.Crawler.adjacent_nodes(graph, curr_node) do
              # If there's no more keys to look for, we're done!
              [] ->
                Agent.update(cache_pid, fn c -> Map.put(c, curr_node, 0) end)
                0

              adj_nodes ->
                # Otherwise we need to find the min distance to the remaining keys
                min_dist_to_curr =
                  adj_nodes
                  |> Enum.map(fn {next_node, dist_to_adj_node} ->
                    dist_to_next = distance + dist_to_adj_node

                    dist_to_adj_node +
                      all_keys_min_distance_dp(graph, next_node, dist_to_next, key_set, cache_pid)
                  end)
                  |> Enum.min()

                # cache this node with the least-distance path so far
                Agent.update(cache_pid, fn c -> Map.put(c, curr_node, min_dist_to_curr) end)
                min_dist_to_curr
            end

          # if getting to this (position, key set) took longer than a cache'd path, no need to explore any more
          cached_distance ->
            cached_distance
        end
      end
    end

    def reachable_keys(
          %Dungeon.State{
            doors_between_keys: doors_bk,
            distances_between_keys: distance_bk,
            keys: keys
          },
          {curr_key, found_keys}
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

    def reachable_nodes(dungeon, {curr_key, found_keys}) do
      reachable_keys(dungeon, {curr_key, found_keys})
      |> Enum.map(fn {new_key, dist} -> {{new_key, MapSet.put(found_keys, new_key)}, dist} end)
    end

    def adjacent_nodes(graph, node) do
      Map.get(graph, node)
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

    def discover_graph(dungeon, source_node) do
      Dungeon.Crawler.reachable_keys(dungeon, source_node)

      discover_graph(:queue.in(source_node, :queue.new()), dungeon, MapSet.new([source_node]))
    end

    defp discover_graph(queue, dungeon, seen) do
      case :queue.out(queue) do
        {:empty, _} ->
          # Explored the whole graph
          seen

        {{:value, {key, found_keys}}, queue} ->
          unseen_adjs =
            Dungeon.Crawler.reachable_keys(dungeon, {key, found_keys})
            |> Enum.map(fn {k, _} -> {k, MapSet.put(found_keys, k)} end)
            |> Enum.filter(fn adj -> !MapSet.member?(seen, adj) end)

          seen = MapSet.union(seen, MapSet.new(unseen_adjs))

          new_queue = Enum.reduce(unseen_adjs, queue, fn adj, q -> :queue.in(adj, q) end)
          discover_graph(new_queue, dungeon, seen)
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

    {:ok, contents} = File.read("input.txt")

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

    source_node = {"@", MapSet.new(["@"])}
    graph_nodes = Dungeon.Crawler.discover_graph(dungeon, source_node)

    IO.inspect("Search space states:")
    IO.inspect(Enum.count(graph_nodes))

    adj_list =
      graph_nodes
      |> Enum.map(fn node -> {node, Dungeon.Crawler.reachable_nodes(dungeon, node)} end)
      |> Enum.into(%{})

    key_set = dungeon.keys |> Map.keys() |> MapSet.new() |> MapSet.put("@")

    # min_dist = Dungeon.Crawler.all_keys_min_distance_dijkstras(adj_list, source_node, key_set)
    min_dist = Dungeon.Crawler.all_keys_min_distance_dp(adj_list, source_node, key_set)

    IO.inspect("Min distance to collect all keys:")
    IO.inspect(min_dist)
  end
end

Main.main()
