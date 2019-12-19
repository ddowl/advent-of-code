Code.require_file("../intcode.ex")

defmodule Arcade do
  @x 43
  @y 20

  def screen(positions_to_tiles) do
    Enum.map(0..@y, fn y ->
      Enum.map(0..@x, fn x ->
        tile_id = Map.get(positions_to_tiles, {x, y}, 0)
        tile_str(tile_id)
      end)
      |> Enum.join()
    end)
    |> Enum.join("\n")
  end

  def tile_str(id) do
    case id do
      0 -> " "
      1 -> "#"
      2 -> "="
      3 -> "_"
      4 -> "o"
    end
  end
end

defmodule BrickBreaker do
  defmodule State do
    defstruct tiles: %{}, ball_pos: nil, paddle_pos: nil, score: 0
  end

  def init(program) do
    # 3 child processes
    # BB program spun up in child process,
    # Tiles/score maintained in separate Agent
    # Event loop maintained by separate process, draws game state and query arrow keys
    # parent process (self) moves output from BB to agent
    parent = self()
    arcade_pid = spawn_link(fn -> ProcessIntcode.execute(program, parent) end)
    {:ok, agent_pid} = Agent.start_link(fn -> %State{} end)
    event_loop_pid = spawn_link(fn -> event_loop(arcade_pid, agent_pid) end)
    state_proxy(agent_pid)
  end

  def state_proxy(agent_pid) do
    x =
      receive do
        {:output, msg} -> msg
      after
        1000 -> nil
      end

    y =
      receive do
        {:output, msg} -> msg
      after
        1000 -> nil
      end

    tile_id =
      receive do
        {:output, msg} -> msg
      after
        1000 -> nil
      end

    if is_nil(x) && is_nil(y) && is_nil(tile_id) do
      nil
    else
      case {x, y, tile_id} do
        {-1, 0, score} ->
          Agent.update(agent_pid, fn state -> %{state | score: score} end)

        {x, y, tid} ->
          Agent.update(agent_pid, fn state ->
            pos = {x, y}
            new_tiles = Map.put(state.tiles, pos, tid)

            case tid do
              4 -> %{state | tiles: new_tiles, ball_pos: pos}
              3 -> %{state | tiles: new_tiles, paddle_pos: pos}
              _ -> %{state | tiles: new_tiles}
            end
          end)
      end

      state_proxy(agent_pid)
    end
  end

  def event_loop(arcade_pid, agent_pid) do
    state = Agent.get(agent_pid, fn s -> s end)
    IO.write("\n")
    IO.puts(state.score)
    IO.puts(Arcade.screen(state.tiles))

    send(arcade_pid, {:input, joystick_input(state.ball_pos, state.paddle_pos)})
    Process.sleep(10)
    event_loop(arcade_pid, agent_pid)
  end

  defp joystick_input({ball_x, _}, {paddle_x, _}) do
    d = ball_x - paddle_x

    cond do
      d > 0 -> 1
      d == 0 -> 0
      d < 0 -> -1
    end
  end

  defp joystick_input(_, _), do: 0
end

{:ok, intcode_str} = File.read("input.txt")

arcade_program =
  intcode_str
  |> String.trim()
  |> String.split(",")
  |> Enum.map(&String.to_integer/1)
  |> List.to_tuple()

IO.inspect(arcade_program)

# Part 1
arcade_output = TtyIntcode.execute(arcade_program) |> Enum.reverse()

tiles_to_positions =
  arcade_output
  |> Enum.chunk_every(3)
  |> List.foldl(%{}, fn [x, y, tile_id], acc ->
    positions_with_type = Map.get(acc, tile_id, [])
    Map.put(acc, tile_id, [{x, y} | positions_with_type])
  end)

IO.inspect(Map.get(tiles_to_positions, 2) |> Enum.count())

# Part 2
fixed_arcade_program = put_elem(arcade_program, 0, 2)
BrickBreaker.init(fixed_arcade_program)
