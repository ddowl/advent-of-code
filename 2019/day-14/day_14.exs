defmodule Nanofactory do
  def required_ore(product, n, reactions) do
    required_compounds(%{product => n}, reactions)
    |> Enum.find(fn {x, _} -> x == "ORE" end)
    |> elem(1)
  end

  def required_compounds(products, reactions) do
    next_composite =
      products
      |> Map.keys()
      |> Enum.find(fn p ->
        num_required = Map.get(products, p)
        p != "ORE" && num_required > 0
      end)

    case next_composite do
      nil ->
        products

      _ ->
        # update products with 1 substitution at a time, until all products have
        # been broken down into consituents
        num_required_composite = Map.get(products, next_composite)
        {yield, reactants} = Map.get(reactions, next_composite)
        reruns = trunc(Float.ceil(num_required_composite / yield))

        total_composite_yield = yield * reruns
        leftover_composite = total_composite_yield - num_required_composite
        removed_composites = Map.put(products, next_composite, -leftover_composite)

        next_products =
          List.foldl(reactants, removed_composites, fn {r, n}, acc ->
            prev_n = Map.get(acc, r, 0)
            Map.put(acc, r, prev_n + reruns * n)
          end)

        required_compounds(next_products, reactions)
    end
  end

  def max_fuel(num_ores, reactions) do
    max_fuel(0, 100_000_000, num_ores, reactions)
  end

  defp max_fuel(lo, hi, limit, reactions) do
    if hi - lo < 2 do
      nil
    else
      mid = div(hi - lo, 2) + lo
      fuel = required_ore("FUEL", mid, reactions)

      if fuel <= limit do
        # want to return the largest amount under limit
        case max_fuel(mid, hi, limit, reactions) do
          nil -> {mid, fuel}
          x -> x
        end
      else
        max_fuel(lo, mid, limit, reactions)
      end
    end
  end
end

# Community inputs
# ex6 requires 20 ORE
{:ok, contents} = File.read("input.txt")

reactions =
  contents
  |> String.trim()
  |> String.split("\n")
  |> Enum.map(fn s ->
    [reactants, products] = String.split(s, " => ")
    [n, product] = String.split(products, " ")

    {
      product,
      String.to_integer(n),
      reactants
      |> String.split(", ")
      |> Enum.map(fn rs ->
        [m, reactant] = String.split(rs, " ")
        {reactant, String.to_integer(m)}
      end)
    }
  end)
  |> List.foldl(%{}, fn {product, yield, reactants}, acc ->
    Map.put(acc, product, {yield, reactants})
  end)

# Part 1
ore_per_fuel = Nanofactory.required_ore("FUEL", 1, reactions)
IO.inspect(ore_per_fuel)

# Part 2
num_ores = 1_000_000_000_000
{max_fuel_given_ores, _ores_used} = Nanofactory.max_fuel(num_ores, reactions)
IO.inspect(max_fuel_given_ores)
