{:ok, contents} = File.read("ex1.txt")

moons =
  contents
  |> String.trim()
  |> String.split("\n")
  |> Enum.map(fn s ->
    s
    |> String.replace(~r/[<>]/, "")
    |> String.split(", ")
    |> Enum.map(fn p ->
      p |> String.slice(2, String.length(p)) |> String.to_integer()
    end)
    |> List.to_tuple()
  end)

IO.inspect(moons)
