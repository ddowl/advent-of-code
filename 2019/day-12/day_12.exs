defmodule MoonSim do
  def num_steps_till_repeat(moons) do
    # store previous states as hashes in a MapSet
    seen_states = MapSet.new()
    num_steps_till_repeat(moons, seen_states, 0)
  end

  def num_steps_till_repeat(moons, seen_states, curr_step) do
    IO.inspect(curr_step)
    # hash = :crypto.hash(:md5, moons)

    if MapSet.member?(seen_states, moons) do
      curr_step
    else
      next_moons = tick(moons)
      next_seen = MapSet.put(seen_states, moons)
      next_step = curr_step + 1
      num_steps_till_repeat(next_moons, next_seen, next_step)
    end
  end

  def simulate(moons, 0), do: moons

  def simulate(moons, n) do
    moons
    |> tick()
    |> simulate(n - 1)
  end

  def tick(moons) do
    # First, update velocity w/ gravity
    # Then, update positions w/ velocity
    moons |> apply_gravity() |> apply_velocity()
  end

  # Updates moons' velocities based on their positions wrt each other
  def apply_gravity(moons) do
    Enum.map(moons, fn {pos, vel} ->
      other_moon_positions =
        moons
        |> Enum.reject(fn {p, _} -> p == pos end)
        |> Enum.map(fn {p, _} -> p end)

      new_vel =
        List.foldl(other_moon_positions, vel, fn p, acc_vel ->
          vel_diff = p |> vector_diff(pos) |> Enum.map(&gravity_effect/1)
          vector_sum(acc_vel, vel_diff)
        end)

      {pos, new_vel}
    end)
  end

  def apply_velocity(moons) do
    Enum.map(moons, fn {pos, vel} -> {vector_sum(pos, vel), vel} end)
  end

  def energy(moons) do
    moons
    |> Enum.map(fn moon -> potential_energy(moon) * kinetic_energy(moon) end)
    |> Enum.sum()
  end

  def potential_energy({pos, _}), do: abs_sum(pos)

  def kinetic_energy({_, vel}), do: abs_sum(vel)

  defp abs_sum(v), do: v |> Enum.map(&abs/1) |> Enum.sum()

  defp vector_sum(a, b) do
    vector_op(a, b, fn a, b -> a + b end)
  end

  defp vector_diff(a, b) do
    vector_op(a, b, fn a, b -> a - b end)
  end

  defp vector_op(vec_a, vec_b, f) do
    List.zip([vec_a, vec_b]) |> Enum.map(fn {a, b} -> f.(a, b) end)
  end

  defp gravity_effect(delta) do
    cond do
      delta < 0 -> -1
      delta > 0 -> 1
      delta == 0 -> 0
    end
  end
end

{:ok, contents} = File.read("ex2.txt")

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

# Part 1
IO.inspect(MoonSim.simulate(moons, 1000))
IO.inspect(moons |> MoonSim.simulate(1000) |> MoonSim.energy())

# Part 2
n = MoonSim.num_steps_till_repeat(moons)
IO.inspect(n)
