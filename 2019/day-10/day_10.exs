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

  def detectable(station, asteroids) do
    asteroids
    |> MapSet.to_list()
    |> Enum.sort_by(fn a -> manhattan_distance(station, a) end)
    |> List.foldl({[], MapSet.new()}, fn asteroid, {acc, seen_angles} ->
      s = angle(station, asteroid)

      if MapSet.member?(seen_angles, s) do
        {acc, seen_angles}
      else
        {[asteroid | acc], MapSet.put(seen_angles, s)}
      end
    end)
    |> elem(0)
  end

  def relative_angles(station, asteroids) do
    asteroids
    |> MapSet.to_list()
    |> Enum.sort_by(fn a -> manhattan_distance(station, a) end)
    |> List.foldl(%{}, fn asteroid, acc -> Map.put(acc, asteroid, angle(station, asteroid)) end)
  end
end

{:ok, contents} = File.read("ex5.txt")

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

# Part 1
{best_station, detectable_asteroids} =
  asteroids
  |> Enum.map(fn a ->
    other_asteroids = MapSet.delete(asteroids, a)
    num_detectable_asteroids = Asteroids.detectable(a, other_asteroids) |> Enum.count()
    {a, num_detectable_asteroids}
  end)
  |> Enum.max_by(fn {_, n} -> n end)

IO.inspect(detectable_asteroids)

# Part 2
# Need to rotate from -90 to 0, 0 to 180, -180 to -90 for full rotation
other_asteroids = MapSet.delete(asteroids, best_station)
# Asteroids.detectable(best_station, other_asteroids)
# IO.inspect(Asteroids.relative_angles(best_station, other_asteroids))
