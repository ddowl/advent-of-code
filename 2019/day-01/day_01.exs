defmodule Fuel do
  def module_fuel(mass) do
    floor(mass / 3) - 2
  end

  def module_fuel_integral(mass) do
    fuel_weights_list(mass) |> Enum.drop(1) |> Enum.sum()
  end

  defp fuel_weights_list(mass) do
    fuel = module_fuel(mass)

    if fuel <= 0 do
      [mass]
    else
      [mass | fuel_weights_list(fuel)]
    end
  end
end

{:ok, contents} = File.read("input.txt")

module_masses =
  contents
  |> String.split("\n", trim: true)
  |> Enum.map(fn s ->
    {n, ""} = Integer.parse(s)
    n
  end)

total_fuel = module_masses |> Enum.map(&Fuel.module_fuel/1) |> Enum.sum()

# Part One
IO.inspect(total_fuel)

total_fuel_integral = module_masses |> Enum.map(&Fuel.module_fuel_integral/1) |> Enum.sum()

# Part Two
IO.inspect(total_fuel_integral)
