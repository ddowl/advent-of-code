defmodule Orbits do
  def indirect_orbit_len(graph, object) do
    case Map.get(graph, object) do
      nil ->
        0

      directly_orbits ->
        1 + indirect_orbit_len(graph, directly_orbits)
    end
  end

  def indirect_orbit_path_to_root(graph, object) do
    case Map.get(graph, object) do
      nil ->
        [object]

      directly_orbits ->
        [object | indirect_orbit_path_to_root(graph, directly_orbits)]
    end
  end

  def distance(object_graph, objA, objB) do
    # First, find the paths to the root
    root_a_path = Orbits.indirect_orbit_path_to_root(object_graph, objA) |> Enum.reverse()
    root_b_path = Orbits.indirect_orbit_path_to_root(object_graph, objB) |> Enum.reverse()

    # traverse them while they're the same
    {common_ancestor_to_a, common_ancestor_to_b} = drop_while_same(root_a_path, root_b_path)

    # sum the distances of the path remainders
    Enum.count(common_ancestor_to_a) + Enum.count(common_ancestor_to_b)
  end

  defp drop_while_same([headA | restA], [headB | restB]) do
    if headA == headB do
      drop_while_same(restA, restB)
    else
      {[headA | restA], [headB | restB]}
    end
  end
end

{:ok, contents} = File.read("input.txt")

# Part 1: Sum of direct and indirect orbits
# Strategy: Represent orbits as a tree of objects, where an edge represents a direct orbit.
# If B directly orbits A, that would be represented as %{B: A}.
# For each object, we can walk the tree to determine its longest path and sum them.

IO.inspect(contents)

object_graph =
  contents
  |> String.split("\n", trim: true)
  |> Enum.map(fn x -> String.split(x, ")") end)
  |> List.foldl(%{}, fn [orbits, orbiter], graph ->
    Map.put(graph, orbiter, orbits)
  end)

IO.inspect(object_graph)

total_indirect_orbits =
  object_graph
  |> Map.keys()
  |> Enum.map(fn orbiter -> Orbits.indirect_orbit_len(object_graph, orbiter) end)
  |> Enum.sum()

IO.inspect(total_indirect_orbits)

# Part 2: Determine the minimal number of orbital transfers from YOU to SAN (Santa)
# This is like finding the least common ancestor of YOU and SAN's orbiting objects,
# and summing the distances to that ancestor.

you_obj = Map.get(object_graph, "YOU")
san_obj = Map.get(object_graph, "SAN")

IO.inspect(Orbits.distance(object_graph, you_obj, san_obj))
