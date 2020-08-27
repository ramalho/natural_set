# NaturalSet

[`NaturalSet`](https://hexdocs.pm/natural_set/NaturalSet.html) is an alternative set type in Elixir,
designed to hold sets of small, non-negative integers.

The name is a reference to the mathematical set ℕ₀ = {0, 1, 2, 3, ...}.

`NaturalSet` emulates the full `MapSet` interface,
except for `MapSet.size` which is replaced by `NaturalSet.length`.
Many of the `NaturalSet` doctests and unit tests were adapted from `MapSet`.

`NaturalSet` illustrates the construction of a functional data structure from scratch,
implementing protocols—`Inspect`, `Enumerable`, `Collectable`—and a stream.

All the content of an `NaturalSet` is represented by a single integer,
which in Elixir is limited only by available memory.
Each bit in that integer represents one element:
a bit set to `1` at position `n` means the number `n` is present in the set.

```elixir
    iex> s = NaturalSet.new([0, 2, 3])
    #NaturalSet<[0, 2, 3]>
    iex> s.bits
    13
    iex> s.bits |> Integer.to_string(2)
    "1101"
```

Using an integer as a bit vector we can use fast bitwise operators
for set operations like intersection and difference.
See the source code of `NaturalSet.intersection` and `NaturalSet.difference`.

Documentation with examples: https://hexdocs.pm/natural_set/NaturalSet.html.

## Source of this idea

This package was inspired by the excellent [`intset` example](https://github.com/adonovan/gopl.io/blob/master/ch6/intset/intset.go) from chapter 6 of
[_The Go Programming Language_](http://www.gopl.io/), by Alan. A. A. Donovan and Brian W. Kernighan.

Here is how Donovan & Kernighan introduce the example:

> A set represented by a map is very flexible but, for certain problems,
> a specialized representation may outperform it. For example, in domains
> such as dataflow analysis where set elements are small non-negative integers,
> sets have many elements, and set operations like union and intersection are common,
> a *bit vector* is ideal.

## About the implementation

Storing a set as a bit vector is efficient only for sets of small integers,
or high-density sets where a large percentage of the possible elements are present.
The memory usage is proportional to the largest element stored,
not to the number of elements in the set.
For example, if the largest element is 1_000_000,
the bit vector size will be 125_000 bytes (⅛),
regardless of the number of elements in the set.

Donovan & Kerninghan's example uses an `uint64[]` slice (dynamic array) to store elements in blocks of 64 bits. They loop over slices performing bitwise operations in each 64-bit block, which
in Elixir we do in a single expression like `bits1 &&& bits2` because the bit vector is stored in a single integer. Go also has a `big.Int` type, but they chose not to use it.
