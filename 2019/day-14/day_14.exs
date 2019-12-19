defmodule Nanofactory do
  def required_ore("ORE", n, _), do: n

  def required_ore(product, n, reactions) do
    {yield, reactants} = Map.get(reactions, product)

    ore_for_yield_num_products =
      reactants
      |> Enum.map(fn {reactant, m} -> required_ore(reactant, m, reactions) end)
      |> Enum.sum()

    over_n(n, yield) * ore_for_yield_num_products
  end

  def over_n(n, yield) do
    over_n(n, yield, yield, 1)
  end

  def over_n(n, acc, step, count) do
    if acc >= n do
      count
    else
      over_n(n, acc + step, step, count + 1)
    end
  end
end

{:ok, contents} = File.read("ex1.txt")

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

IO.inspect(reactions)

# Part 1
IO.inspect({"ORE", Nanofactory.required_ore("ORE", 10, reactions)})
IO.inspect({"A", Nanofactory.required_ore("A", 10, reactions)})
IO.inspect({"A", Nanofactory.required_ore("A", 7, reactions)})
IO.inspect({"B", Nanofactory.required_ore("B", 10, reactions)})
IO.inspect({"C", Nanofactory.required_ore("C", 1, reactions)})
IO.inspect({"D", Nanofactory.required_ore("D", 1, reactions)})
IO.inspect({"E", Nanofactory.required_ore("E", 1, reactions)})
IO.inspect({"FUEL", Nanofactory.required_ore("FUEL", 1, reactions)})
