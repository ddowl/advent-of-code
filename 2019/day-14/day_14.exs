{:ok, contents} = File.read("ex1.txt")

reactions =
  contents
  |> String.trim()
  |> String.split("\n")

IO.inspect(reactions)
