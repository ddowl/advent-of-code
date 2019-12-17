Code.require_file("../intcode.ex")

defmodule Robot do
  # Possible directions are [:up, :down, :left, :right]
  defstruct position: {0, 0}, direction: :up

  def move(robot) do
    {x, y} = robot.position

    case robot.direction do
      :up -> %{robot | position: {x, y + 1}}
      :down -> %{robot | position: {x, y - 1}}
      :left -> %{robot | position: {x - 1, y}}
      :right -> %{robot | position: {x + 1, y}}
      _ -> raise "invalid direction"
    end
  end

  def update_direction(robot, code) do
    new_dir =
      case code do
        0 ->
          case robot.direction do
            :up -> :left
            :left -> :down
            :down -> :right
            :right -> :up
          end

        1 ->
          case robot.direction do
            :up -> :right
            :right -> :down
            :down -> :left
            :left -> :up
          end
      end

    %{robot | direction: new_dir}
  end
end

defmodule Painter do
  def init(painter_program, panels) do
    parent = self()
    painter_pid = spawn_link(fn -> ProcessIntcode.execute(painter_program, parent) end)
    execute(%Robot{}, panels, painter_pid)
  end

  def execute(robot, panels, painter_pid) do
    # repeatedly provide 1 value, current tile color
    # wait for 2 values, color to paint and next direction

    # non-painted panels are black
    curr_panel_color = Map.get(panels, robot.position, 0)

    send(painter_pid, {:input, curr_panel_color})

    next_color =
      receive do
        {:output, c} -> c
      after
        1_000 -> nil
      end

    next_dir =
      receive do
        {:output, d} -> d
      after
        1_000 -> nil
      end

    if is_nil(next_color) && is_nil(next_dir) do
      panels
    else
      next_panels = Map.put(panels, robot.position, next_color)
      next_robot = robot |> Robot.update_direction(next_dir) |> Robot.move()

      execute(next_robot, next_panels, painter_pid)
    end
  end

  # Matrix of chars, '.' is a black panel, '#' is a white panel
  def hull_ascii(panels) do
    panel_positions = Map.keys(panels)
    xs = Enum.map(panel_positions, fn {x, _} -> x end)
    ys = Enum.map(panel_positions, fn {_, y} -> y end)
    max_x = Enum.max(xs)
    min_x = Enum.min(xs)
    max_y = Enum.max(ys)
    min_y = Enum.min(ys)

    max_y..min_y
    |> Enum.map(fn y ->
      min_x..max_x
      |> Enum.map(fn x ->
        color_code = Map.get(panels, {x, y}, 0)

        case color_code do
          0 -> '.'
          1 -> '#'
        end
      end)
      |> Enum.join(" ")
    end)
    |> Enum.join("\n")
  end
end

{:ok, intcode_str} = File.read("input.txt")

painter_program =
  intcode_str
  |> String.trim()
  |> String.split(",")
  |> Enum.map(&String.to_integer/1)
  |> List.to_tuple()

# Part 1
panels = Painter.init(painter_program, %{})

num_panels_painted = panels |> Map.keys() |> Enum.count()
IO.inspect(num_panels_painted)

# Part 2
panels = Painter.init(painter_program, %{{0, 0} => 1})
ascii = Painter.hull_ascii(panels)
IO.puts(ascii)
