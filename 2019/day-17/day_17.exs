Code.require_file("../intcode.ex")

defmodule Scaffold do
  def at(grid, x, y), do: elem(elem(grid, y), x)

  def intersection?(grid, x, y) do
    curr = Scaffold.at(grid, x, y)
    up = Scaffold.at(grid, x, y - 1)
    down = Scaffold.at(grid, x, y + 1)
    left = Scaffold.at(grid, x - 1, y)
    right = Scaffold.at(grid, x + 1, y)

    Enum.all?([curr, up, down, left, right], fn x -> x == "#" end)
  end
end

{:ok, intcode_str} = File.read("input.txt")

scaffold_control_program =
  intcode_str
  |> String.trim()
  |> String.split(",")
  |> Enum.map(&String.to_integer/1)
  |> List.to_tuple()

aft_view_charlist = TtyIntcode.execute(scaffold_control_program)
IO.puts(aft_view_charlist)
IO.inspect(aft_view_charlist)

# {:ok, aft_view_str} = File.read("ex1.part1")
# IO.puts(aft_view_str)

aft_view_grid =
  aft_view_charlist
  |> to_string
  |> String.split("\n", trim: true)
  |> Enum.map(fn s -> List.to_tuple(String.split(s, "", trim: true)) end)
  |> List.to_tuple()

max_y = tuple_size(aft_view_grid)
max_x = tuple_size(elem(aft_view_grid, 0))

intersection_points =
  Enum.map(1..(max_y - 2), fn y ->
    Enum.map(1..(max_x - 2), fn x ->
      if Scaffold.intersection?(aft_view_grid, x, y) do
        {x, y}
      else
        nil
      end
    end)
  end)
  |> List.flatten()
  |> Enum.reject(&is_nil/1)

IO.inspect(intersection_points)

sum_of_alignment_params =
  intersection_points
  |> Enum.map(fn {x, y} -> x * y end)
  |> Enum.sum()

IO.inspect(sum_of_alignment_params)
