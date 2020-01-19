defmodule Dungeon do
  defmodule State do
    defstruct [
      :doors,
      :keys,
      :distances_between_keys,
      :doors_between_keys
    ]
  end

  defmodule Crawler do
    def all_keys_min_distance_dp(graph, source_node, key_set) do
      {:ok, path_cache_pid} = Agent.start_link(fn -> %{} end)
      shortest_path_len = all_keys_min_distance_dp(graph, source_node, 0, key_set, path_cache_pid)
      Agent.stop(path_cache_pid)
      shortest_path_len
    end

    # Memoize min distance to path (location, keys_held)
    defp all_keys_min_distance_dp(graph, curr_node, distance, key_set, cache_pid) do
      if MapSet.equal?(elem(curr_node, 1), key_set) do
        0
      else
        case Agent.get(cache_pid, fn c -> Map.get(c, curr_node) end) do
          nil ->
            adj_nodes = Dungeon.Crawler.adjacent_nodes(graph, curr_node)

            # Otherwise we need to find the min distance to the remaining keys
            min_dist_to_curr =
              adj_nodes
              |> Enum.map(fn {next_node, dist_to_adj_node} ->
                dist_to_next = distance + dist_to_adj_node

                dist_to_goal =
                  all_keys_min_distance_dp(graph, next_node, dist_to_next, key_set, cache_pid)

                dist_to_adj_node + dist_to_goal
              end)
              |> Enum.min()

            # cache this node with the least-distance path so far
            Agent.update(cache_pid, fn c -> Map.put(c, curr_node, min_dist_to_curr) end)
            min_dist_to_curr

          # if getting to this (position, key set) took longer than a cache'd path, no need to explore any more
          cached_distance ->
            cached_distance
        end
      end
    end

    def adjacent_nodes(graph, node) do
      Map.get(graph, node)
    end

    def reachable_nodes(dungeon, {curr_key, found_keys}) do
      reachable_keys(dungeon, {curr_key, found_keys})
      |> Enum.map(fn {new_key, dist} -> {{new_key, MapSet.put(found_keys, new_key)}, dist} end)
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

    defp adjacent_open_spaces(open_spaces, {x, y}) do
      [{x + 1, y}, {x - 1, y}, {x, y + 1}, {x, y - 1}]
      |> Enum.filter(fn pos -> MapSet.member?(open_spaces, pos) end)
    end

    def bfs(a, b, init_val, adj_fn, tracking_update_fn) do
      queue = :queue.in({a, init_val}, :queue.new())
      seen = MapSet.new([a])
      bfs_helper(queue, b, seen, adj_fn, tracking_update_fn)
    end

    defp bfs_helper(queue, goal, seen, adj_fn, tracking_update_fn) do
      case :queue.out(queue) do
        {:empty, _} ->
          # could not find a path
          seen

        {{:value, {node, acc}}, queue} ->
          if node == goal do
            # found the goal!
            acc
          else
            unseen_adjs =
              adj_fn.(node)
              |> Enum.filter(fn adj -> !MapSet.member?(seen, adj) end)

            seen = MapSet.union(seen, MapSet.new(unseen_adjs))

            new_queue =
              Enum.reduce(unseen_adjs, queue, fn adj, q ->
                :queue.in({adj, tracking_update_fn.(adj, acc)}, q)
              end)

            bfs_helper(new_queue, goal, seen, adj_fn, tracking_update_fn)
          end
      end
    end

    def distance_from(a, b, spaces) do
      adj_nodes_fn = fn node -> adjacent_open_spaces(spaces, node) end
      inc_fn = fn _, acc -> acc + 1 end
      bfs(a, b, 0, adj_nodes_fn, inc_fn)
    end

    def doors_between(a, b, spaces, doors) do
      adj_nodes_fn = fn node -> adjacent_open_spaces(spaces, node) end

      update_doors_fn = fn adj, acc ->
        case Map.get(doors, adj) do
          nil -> acc
          sym -> MapSet.put(acc, sym)
        end
      end

      bfs(a, b, MapSet.new(), adj_nodes_fn, update_doors_fn)
    end

    def discover_graph(dungeon, source_node) do
      adj_nodes_fn = fn node ->
        Dungeon.Crawler.reachable_nodes(dungeon, node)
        |> Enum.map(fn {n, _} -> n end)
      end

      update_tracking_fn = fn _, _ -> nil end

      bfs(source_node, nil, nil, adj_nodes_fn, update_tracking_fn)
    end
  end
end

defmodule Main do
  def main do
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

    dungeon = %Dungeon.State{
      keys: keys,
      doors: doors,
      distances_between_keys: distances_between_keys,
      doors_between_keys: doors_between_keys
    }

    source_node = {"@", MapSet.new(["@"])}
    graph_nodes = Dungeon.Crawler.discover_graph(dungeon, source_node)

    adj_list =
      graph_nodes
      |> Enum.map(fn node -> {node, Dungeon.Crawler.reachable_nodes(dungeon, node)} end)
      |> Enum.into(%{})

    key_set = dungeon.keys |> Map.keys() |> MapSet.new() |> MapSet.put("@")
    min_dist = Dungeon.Crawler.all_keys_min_distance_dp(adj_list, source_node, key_set)
    IO.inspect(min_dist)
  end
end

Main.main()
