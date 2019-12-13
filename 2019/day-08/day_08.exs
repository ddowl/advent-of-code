{:ok, contents} = File.read("input.txt")

defmodule Layer do
  @img_width 25
  @img_height 6
  def width, do: @img_width
  def height, do: @img_height

  def print(layer) do
    layer
    |> Tuple.to_list()
    |> Enum.chunk_every(@img_width)
    |> Enum.map(&Enum.join/1)
    |> Enum.each(&IO.puts/1)
  end
end

layers =
  contents
  |> String.graphemes()
  |> Enum.map(&String.to_integer/1)
  |> Enum.chunk_every(Layer.width() * Layer.height())

IO.inspect(layers)

# Part 1
layer_least_zeros =
  layers
  |> Enum.min_by(fn layer -> Enum.count(layer, fn x -> x == 0 end) end)

IO.inspect(layer_least_zeros)

num_ones = Enum.count(layer_least_zeros, fn x -> x == 1 end)
num_twos = Enum.count(layer_least_zeros, fn x -> x == 2 end)

IO.inspect(num_ones * num_twos)

# Part 2
layers = Enum.map(layers, &List.to_tuple/1)

transparent_img = List.duplicate(2, Layer.width() * Layer.height()) |> Enum.with_index()

decoded_img =
  List.foldl(layers, transparent_img, fn layer, acc ->
    acc
    |> Enum.map(fn {digit, idx} ->
      new_digit =
        case digit do
          2 ->
            elem(layer, idx)

          n ->
            n
        end

      {new_digit, idx}
    end)
  end)
  |> Enum.map(fn {d, i} -> d end)
  |> List.to_tuple()

IO.puts("Decoded image")
Layer.print(decoded_img)
