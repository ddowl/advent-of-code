defmodule Grid do
  @origin {0, 0}
  def build_wire_points(instrs) do
    [@origin | build_wire_points(instrs, @origin)]
  end

  defp build_wire_points([], _), do: []

  defp build_wire_points([next_instr | rest], {curr_x, curr_y}) do
    next_point =
      case next_instr do
        {"U", dist} ->
          {curr_x, curr_y + dist}

        {"D", dist} ->
          {curr_x, curr_y - dist}

        {"L", dist} ->
          {curr_x - dist, curr_y}

        {"R", dist} ->
          {curr_x + dist, curr_y}
      end

    [next_point | build_wire_points(rest, next_point)]
  end

  def segments_overlap?([{a_x1, a_y1}, {a_x2, a_y2}], [{b_x1, b_y1}, {b_x2, b_y2}]) do
    # A is vertical, B is vertical
    # or
    # A is vertical, B is hortizonal
    (a_y1 in b_y1..b_y2 && b_x1 in a_x1..a_x2) ||
      (a_x1 in b_x1..b_x2 && b_y1 in a_y1..a_y2)
  end

  # Assumes segments are already overlapping
  def intersection_point([{a_x1, a_y1}, {a_x2, a_y2}], [{b_x1, b_y1}, {b_x2, b_y2}]) do
    a_is_vertical = a_x1 == a_x2
    b_is_vertical = b_x1 == b_x2

    cond do
      a_is_vertical && !b_is_vertical ->
        {a_x1, b_y1}

      !a_is_vertical && b_is_vertical ->
        {b_x1, a_y1}

      true ->
        # overlapping vertical or horizontal lines can have infinite intersection points
        nil
    end
  end

  def manhattan_distance_from_origin(point), do: manhattan_distance(@origin, point)

  # https://en.wikipedia.org/wiki/Taxicab_geometry
  def manhattan_distance({x1, y1}, {x2, y2}) do
    abs(x1 - x2) + abs(y1 - y2)
  end
end

# Strategy: Store lines as a list of line segment points: [{x1, y1}, {x2, y2}, {x3, y3}, ...].
# Determine line intersection if vertical and vertical ranges are non-disjoint among both lines.
# Intersection point is x coord for vertical line, and y coord for vertical line
# Determine manhattan distance for each, extract min

{:ok, contents} = File.read("input.txt")

wire_instructions =
  contents
  |> String.split("\n", trim: true)
  |> Enum.map(fn wire ->
    Enum.map(String.split(wire, ","), fn label ->
      direction = String.first(label)
      distance = label |> String.slice(1..-1) |> String.to_integer()
      {direction, distance}
    end)
  end)

wire_points = wire_instructions |> Enum.map(&Grid.build_wire_points/1)

wire_line_segments = Enum.map(wire_points, fn wire -> Enum.chunk_every(wire, 2, 1, :discard) end)

[a_segments, b_segments] = wire_line_segments

intersection_points =
  for a_segment <- a_segments,
      b_segment <- b_segments,
      Grid.segments_overlap?(a_segment, b_segment) do
    Grid.intersection_point(a_segment, b_segment)
  end

closest_intersection_distance =
  intersection_points
  |> Enum.reject(fn point -> is_nil(point) || point == {0, 0} end)
  |> Enum.map(&Grid.manhattan_distance_from_origin/1)
  |> Enum.min()

# Part 1
IO.puts("Part 1: Closest intersection point manhattan distance")
IO.inspect(closest_intersection_distance)

wire_line_segments_and_distances =
  Enum.map(wire_line_segments, fn wire ->
    List.foldl(wire, [], fn [a, b], prev_segments ->
      length = Grid.manhattan_distance(a, b)

      prev_steps =
        case prev_segments do
          [] -> 0
          [{_segs, steps} | _rest] -> steps
        end

      [{[a, b], length + prev_steps} | prev_segments]
    end)
    |> Enum.reverse()
  end)

[a_segments, b_segments] = wire_line_segments_and_distances

steps_to_intersections =
  for {a, a_cum_len} <- a_segments,
      {b, b_cum_len} <- b_segments,
      Grid.segments_overlap?(a, b) do
    p = Grid.intersection_point(a, b)

    case p do
      nil ->
        nil

      p ->
        [_first_a, second_a] = a
        [_first_b, second_b] = b
        extra_a_len = Grid.manhattan_distance(p, second_a)
        extra_b_len = Grid.manhattan_distance(p, second_b)

        {a_cum_len - extra_a_len, b_cum_len - extra_b_len}
    end
  end

fewest_intersection_steps =
  steps_to_intersections
  |> Enum.reject(fn steps -> is_nil(steps) || steps == {0, 0} end)
  |> Enum.map(fn {a_steps, b_steps} -> a_steps + b_steps end)
  |> Enum.min()

# Part 2
IO.puts("Part 2: Fewest steps to intersection point")
IO.inspect(fewest_intersection_steps)
