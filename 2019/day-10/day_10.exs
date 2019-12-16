defmodule Asteroids do
  # https://en.wikipedia.org/wiki/Taxicab_geometry
  def manhattan_distance({x1, y1}, {x2, y2}) do
    abs(x1 - x2) + abs(y1 - y2)
  end

  def distance({x1, y1}, {x2, y2}) do
    :math.sqrt(:math.pow(x2 - x1, 2) + :math.pow(y2 - y1, 2))
  end

  def slope({x1, y1}, {x2, y2}) do
    dy = y2 - y1
    dx = x2 - x1

    if dx == 0 do
      if dy >= 0 do
        :inf
      else
        :neg_inf
      end
    else
      dy / dx
    end
  end

  def angle({x1, y1}, {x2, y2}) do
    dy = y2 - y1
    dx = x2 - x1

    :math.atan2(dy, dx) * (180 / :math.pi())
  end

  def detectable(station, candidates) do
    candidates
    |> MapSet.to_list()
    |> Enum.sort_by(fn a -> manhattan_distance(station, a) end)
    |> List.foldl({[], MapSet.new()}, fn asteroid, {acc, seen_angles} ->
      s = angle(station, asteroid)
      # IO.inspect({asteroid, s, seen_angles})

      if MapSet.member?(seen_angles, s) do
        {acc, seen_angles}
      else
        {[asteroid | acc], MapSet.put(seen_angles, s)}
      end
    end)
    |> elem(0)
  end
end

{:ok, contents} = File.read("input.txt")

asteroids =
  contents
  |> String.split("\n")
  |> Enum.map(fn row -> row |> String.graphemes() |> Enum.with_index() end)
  |> Enum.with_index()
  |> List.foldl(MapSet.new(), fn {row, y_idx}, acc ->
    asteroids_in_row =
      List.foldl(row, MapSet.new(), fn {char, x_idx}, row_acc ->
        case char do
          "#" -> MapSet.put(row_acc, {x_idx, y_idx})
          _ -> row_acc
        end
      end)

    MapSet.union(acc, asteroids_in_row)
  end)

# IO.inspect(asteroids)

best_station =
  asteroids
  |> Enum.map(fn a ->
    other_asteroids = MapSet.delete(asteroids, a)
    num_detectable_asteroids = Asteroids.detectable(a, other_asteroids) |> Enum.count()
    {a, num_detectable_asteroids}
  end)
  |> Enum.max_by(fn {_, n} -> n end)

IO.inspect(best_station)
# IO.inspect(Asteroids.detectable({5, 8}, MapSet.delete(asteroids, {5, 8})) |> Enum.count())
