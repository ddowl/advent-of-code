defmodule Fuel do
  def required(mass) do
    floor(mass / 3) - 2
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

total_fuel = module_masses |> Enum.map(&Fuel.required/1) |> Enum.sum()

# Part One
IO.inspect(total_fuel)
