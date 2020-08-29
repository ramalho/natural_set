#! /usr/bin/env elixir

defmodule Fibonacci do
  @doc ~S"""
  Generates numbers from the Fibonacci sequence up to `max`.

  ## Example

   iex> > Fibonacci.sequence(100) |> Enum.to_list
   [0, 1, 1, 2, 3, 5, 8, 13, 21, 34, 55, 89]
  """
  def sequence(max) do
    Stream.unfold({0, 1}, fn
      {a, _} when a > max -> nil
      {a, b} -> {a, {b, a + b}}
    end)
  end

  def main do
    case System.argv() do
      [] -> 1000
      [arg | _] -> String.to_integer(arg)
    end
    |> sequence()
    |> Enum.map(&IO.write("#{&1} "))

    IO.puts("")
  end
end

Fibonacci.main()
