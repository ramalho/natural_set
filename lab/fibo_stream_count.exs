#! /usr/bin/env elixir

defmodule Fibonacci do
  @doc ~S"""
  Generates `count` numbers from the Fibonacci sequence.

  ## Example

   iex> > Fibonacci.sequence(10) |> Enum.to_list
   [0, 1, 1, 2, 3, 5, 8, 13, 21, 34]
  """

  def sequence(count) do
    Stream.unfold({count, 0, 1}, fn
      {0, _, _} -> nil
      {count, a, b} -> {a, {count - 1, b, a + b}}
    end)
  end

  def main do
    case System.argv() do
      [] -> 20
      [arg | _] -> String.to_integer(arg)
    end
    |> sequence()
    |> Enum.map(&IO.write("#{&1} "))

    IO.puts("")
  end
end

Fibonacci.main()
