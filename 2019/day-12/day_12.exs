defmodule Simulation do
  def tick(moons) do
    # First, update velocity w/ gravity
    updated_vel = gravity(moons)

    # Then, update positions w/ velocity
  end

  # Updates moons' velocities based on their positions wrt each other
  def gravity(moons) do
    Enum.map(moons, fn {pos, vel} ->
      other_moon_positions =
        moons
        |> Enum.reject(fn {p, _} -> p == pos end)
        |> Enum.map(fn {p, _} -> p end)

      new_vel =
        List.foldl(other_moon_positions, vel, fn p, acc_vel ->
          vel_diff = p |> vector_diff(pos) |> Enum.map(&gravity_effect/1)
          List.zip([acc_vel, vel_diff]) |> Enum.map(fn {a, b} -> a + b end)
        end)

      {pos, new_vel}
    end)
  end

  defp vector_diff([x1, y1, z1], [x2, y2, z2]) do
    [x1 - x2, y1 - y2, z1 - z2]
  end

  defp gravity_effect(delta) do
    cond do
      delta < 0 -> -1
      delta > 0 -> 1
      delta == 0 -> 0
    end
  end
end

{:ok, contents} = File.read("ex1.txt")

moons =
  contents
  |> String.trim()
  |> String.split("\n")
  |> Enum.map(fn s ->
    position =
      s
      |> String.replace(~r/[<>]/, "")
      |> String.split(", ")
      |> Enum.map(fn p ->
        p |> String.slice(2, String.length(p)) |> String.to_integer()
      end)

    {position, [0, 0, 0]}
  end)

IO.inspect(moons)
IO.inspect(Simulation.gravity(moons))
