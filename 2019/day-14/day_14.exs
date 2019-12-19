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

    if is_nil(next_composite) do
      products
    else
      # update products with 1 substitution at a time, until all products have
      # been broken down into consituents
      num_required_composite = Map.get(products, next_composite)
      {yield, reactants} = Map.get(reactions, next_composite)
      reruns = num_required_reactions(num_required_composite, yield)

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

  # TODO: simpler way to specify # of required reactions?
  defp num_required_reactions(n, yield) do
    num_required_reactions(n, yield, yield, 1)
  end

  defp num_required_reactions(n, acc, step, count) do
    if acc >= n do
      count
    else
      num_required_reactions(n, acc + step, step, count + 1)
    end
  end

  defp only_ore([{"ORE", _}]), do: true
  defp only_ore(_), do: false
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

IO.inspect(reactions)

# Part 1
IO.inspect(Nanofactory.required_ore("FUEL", 1, reactions))
