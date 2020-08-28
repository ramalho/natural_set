#!/usr/bin/env elixir

defmodule Fibonacci do

    def sequence(count) do
        Stream.unfold({count, 0, 1}, &next/1)
    end

    defp next({0, _, _}), do: nil

    defp next({count, a, b}), do: {a, {count - 1, b, a + b}}

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
