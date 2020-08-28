#!/usr/bin/env elixir

defmodule Fibonacci do

  @doc ~S"""
  Generates the Fibonacci sequence, limited only by available memory

  ## Example

   iex> Fibonacci.sequence() |> Enum.take(10)
   [0, 1, 1, 2, 3, 5, 8, 13, 21, 34]
  """
  def sequence(), do: Stream.unfold({0, 1}, &next/1)

  defp next({a, b}), do: {a, {b, a + b}}

  def demo do
    count = case System.argv() do
      [] -> 20
      [arg|_] -> String.to_integer(arg)
    end
    sequence()
    |> Enum.take(count)
    |> Enum.map(&IO.write("#{&1} "))
    IO.puts("")
  end

end

Fibonacci.demo
