defmodule Grid do
  @origin {0, 0}
  def build_wire_points(instrs) do
    [@origin | build_wire_points(instrs, @origin)]
  end

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

  def manhattan_distance_from_origin(point), do: manhattan_distance(@origin, point)

  defp build_wire_points([], _), do: []

  # https://en.wikipedia.org/wiki/Taxicab_geometry
  defp manhattan_distance({x1, y1}, {x2, y2}) do
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

IO.puts("Instructions:")
IO.inspect(wire_instructions)
IO.write("\n")

wire_points = wire_instructions |> Enum.map(&Grid.build_wire_points/1)

IO.puts("Points:")
IO.inspect(wire_points)

wire_line_segments = Enum.map(wire_points, fn wire -> Enum.chunk_every(wire, 2, 1, :discard) end)
IO.inspect(wire_line_segments)

[a_segments, b_segments] = wire_line_segments

intersection_points =
  for a_segment <- a_segments,
      b_segment <- b_segments,
      Grid.segments_overlap?(a_segment, b_segment) do
    [{a_x1, a_y1}, {a_x2, a_y2}] = a_segment
    [{b_x1, b_y1}, {b_x2, b_y2}] = b_segment
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

closest_intersection_distance =
  intersection_points
  |> Enum.reject(fn point -> is_nil(point) || point == {0, 0} end)
  |> IO.inspect()
  |> Enum.map(&Grid.manhattan_distance_from_origin/1)
  |> IO.inspect()
  |> Enum.min()

# Part 1
IO.inspect(closest_intersection_distance)
