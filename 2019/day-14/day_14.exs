defmodule Nanofactory do
  def required_ore("ORE", n, _), do: n

  def required_ore(product, n, reactions) do
    compounds = required_compounds(product, n, reactions)

    compounds
    |> Enum.map(fn {c, m} ->
      {yield, [{"ORE", o}]} = Map.get(reactions, c)
      reruns = num_required_reactions(m, yield)
      reruns * o
    end)
    |> Enum.sum()
  end

  # Aggregate all required non-ORE
  def required_compounds("ORE", _, _), do: raise("Cannot call 'ORE' on required_compounds")

  def required_compounds(product, n, reactions) do
    # If product requires only ORE, we're done
    {yield, reactants} = Map.get(reactions, product)

    if only_ore(reactants) do
      [{product, n}]
    else
      reruns = num_required_reactions(n, yield)

      base_compounds =
        reactants
        |> Enum.map(fn {r, m} -> required_compounds(r, m * reruns, reactions) end)
        |> List.flatten()
        |> Enum.group_by(fn {r, _} -> r end, fn {_, m} -> m end)
        |> Enum.map(fn {r, ms} -> {r, Enum.sum(ms)} end)
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

{:ok, contents} = File.read("ex6.txt")

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
# IO.inspect(Nanofactory.required_ore("FUEL", 1, reactions))
IO.inspect(Nanofactory.required_ore("FUEL", 1, reactions))
IO.inspect(Nanofactory.required_compounds("FUEL", 1, reactions))
# IO.inspect(Nanofactory.required_compounds("AB", 2, reactions))
# IO.inspect(Nanofactory.required_compounds("BC", 3, reactions))
# IO.inspect(Nanofactory.required_compounds("CA", 4, reactions))
