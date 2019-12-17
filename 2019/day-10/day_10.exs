defmodule Asteroids do
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

  def partition_angles([], angles), do: {[], angles}

  def partition_angles([x | xs], angles) do
    {other_detectables, remaining_asteroids} = partition_angles(xs, Map.delete(angles, x))
    {[{x, Map.get(angles, x)} | other_detectables], remaining_asteroids}
  end

  def vaporize(detected_queue, undetected_angles) do
    case :queue.out(detected_queue) do
      {:empty, _} ->
        []

      {{:value, {pos, angle}}, rest_queue} ->
        remaining_angles = Map.delete(undetected_angles, pos)

        colinear_asteroids =
          remaining_angles
          |> Enum.filter(fn {_, th} -> th == angle end)

        {rest_queue, remaining_angles} =
          case colinear_asteroids do
            [] ->
              {rest_queue, remaining_angles}

            xs ->
              nearest_colinear_asteroid =
                Enum.min_by(colinear_asteroids, fn {a, _} -> manhattan_distance(pos, a) end)

              {:queue.in(nearest_colinear_asteroid, rest_queue),
               Map.delete(remaining_angles, elem(nearest_colinear_asteroid, 0))}
          end

        [pos | vaporize(rest_queue, remaining_angles)]
    end
  end

  # https://en.wikipedia.org/wiki/Taxicab_geometry
  defp manhattan_distance({x1, y1}, {x2, y2}) do
    abs(x1 - x2) + abs(y1 - y2)
  end

  defp distance({x1, y1}, {x2, y2}) do
    :math.sqrt(:math.pow(x2 - x1, 2) + :math.pow(y2 - y1, 2))
  end

  defp slope({x1, y1}, {x2, y2}) do
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

  defp angle({x1, y1}, {x2, y2}) do
    dy = y2 - y1
    dx = x2 - x1

    :math.atan2(dy, dx) * (180 / :math.pi())
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
asteroid_angles = Asteroids.relative_angles(best_station, other_asteroids)
detectable_asteroids = Asteroids.detectable(best_station, other_asteroids)

{detectable_angles, remaining_angles} =
  Asteroids.partition_angles(detectable_asteroids, asteroid_angles)

sorted_detectable_angles = Enum.sort_by(detectable_angles, fn {_, angle} -> angle end)

num_angles_in_last_quadrant =
  Enum.count(sorted_detectable_angles, fn {_, angle} -> angle < -90 end)

angle_queue = :queue.from_list(sorted_detectable_angles)

{last_quadrant_queue, from_vertical_queue} =
  :queue.split(num_angles_in_last_quadrant, angle_queue)

rotated_angle_queue = :queue.join(from_vertical_queue, last_quadrant_queue)

vaporized_asteroids = Asteroids.vaporize(rotated_angle_queue, remaining_angles)
# IO.inspect(Enum.at(vaporized_asteroids, 0))
# IO.inspect(Enum.at(vaporized_asteroids, 1))
# IO.inspect(Enum.at(vaporized_asteroids, 2))
# IO.inspect(Enum.at(vaporized_asteroids, 9))
# IO.inspect(Enum.at(vaporized_asteroids, 19))
# IO.inspect(Enum.at(vaporized_asteroids, 49))
# IO.inspect(Enum.at(vaporized_asteroids, 99))
# IO.inspect(Enum.at(vaporized_asteroids, 198))
IO.inspect(Enum.at(vaporized_asteroids, 199))
# IO.inspect(Enum.at(vaporized_asteroids, 200))
# IO.inspect(Enum.at(vaporized_asteroids, 298))
