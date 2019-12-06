defmodule Orbits do
  def indirect_orbits(graph, object) do
    directly_orbits = Map.get(graph, object, [])

    if Enum.empty?(directly_orbits) do
      0
    else
      1 +
        Enum.max(Enum.map(directly_orbits, fn inner_obj -> indirect_orbits(graph, inner_obj) end))
    end
  end
end

{:ok, contents} = File.read("input.txt")

# Part 1: Sum of direct and indirect orbits
# Strategy: Represent orbits as an adjacency list graph of objects _that it directly orbits_.
# If B directly orbits A, that would be represented as %{B: [A], A: []}.
# For each object, we can walk the graph to determine its longest path and sum them.

IO.inspect(contents)

object_graph =
  contents
  |> String.split("\n", trim: true)
  |> Enum.map(fn x -> String.split(x, ")") end)
  |> List.foldl(%{}, fn [orbits, orbiter], graph ->
    directly_orbits = Map.get(graph, orbiter, [])
    Map.put(graph, orbiter, [orbits | directly_orbits])
  end)

IO.inspect(object_graph)

total_indirect_orbits =
  object_graph
  |> Enum.map(fn {orbiter, _} -> Orbits.indirect_orbits(object_graph, orbiter) end)
  |> Enum.sum()

IO.inspect(total_indirect_orbits)
