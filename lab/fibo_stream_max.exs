#!/usr/bin/env elixir

defmodule Fibonacci do

  @doc ~S"""
  Generates numbers from the Fibonacci sequence up to `max`.

  ## Example

   iex> > Fibonacci.sequence(50) |> Enum.to_list
   [0, 1, 1, 2, 3, 5, 8, 13, 21, 34]
  """
  def sequence(max), do: Stream.unfold({max, 0, 1}, &next/1)

  defp next({max, a, _}) when a > max, do: nil

  defp next({max, a, b}), do: {a, {max, b, a + b}}

  def main do
    case System.argv() do
      [] -> 20
      [arg|_] -> String.to_integer(arg)
    end
    |> sequence
    |> Enum.map(&IO.write("#{&1} "))
    IO.puts("")
  end

end

Fibonacci.main
