defmodule NaturalSet do
  @moduledoc """
    Functions that work on sets of small integers >= 0.

    `NaturalSet` is an alternative set type in Elixir
    emulating the `MapSet` interface as closely as possible,
    with one important limitation: every element must be a non-negative integers.

    Many of the `NaturalSet` doctests and unit tests were adapted from `MapSet`.
    `NaturalSet` illustrates the construction of a functional data structure from scratch,
    with support for streaming and the `Inspect`, `Enumerable`, and `Collectable` protocols.

    By definition, sets contain unique elements.
    Trying to insert a duplicate is a no-op:

        iex> natural_set = NaturalSet.new()
        #NaturalSet<[]>
        iex> natural_set = NaturalSet.put(natural_set, 3)
        #NaturalSet<[3]>
        iex> natural_set |> NaturalSet.put(2) |> NaturalSet.put(2)
        #NaturalSet<[2, 3]>

    `NaturalSet.new/1` accepts an enumerable of elements:

        iex> NaturalSet.new(1..5)
        #NaturalSet<[1, 2, 3, 4, 5]>

    An `NaturalSet` is represented internally using the `%NaturalSet{}` struct.
    This struct can be used whenever there's a need to pattern match on something being an `NaturalSet`:

        iex> match?(%NaturalSet{}, NaturalSet.new())
        true

    The `%NaturalSet{}` struct contains a single field—`bits`—
    an integer which is used as a bit vector where each bit set to `1` represents
    a number present in the set.

    An empty set is stored as `bits = 0`:

        iex> empty = NaturalSet.new()
        iex> empty.bits
        0
        iex> NaturalSet.member?(empty, 0)
        false

    A set containing just a `0` is stored as `bits = 1`,
    because the bit at `0` is set, so the element `0` is present:

        iex> set_with_zero = NaturalSet.new([0])
        iex> set_with_zero.bits
        1
        iex> NaturalSet.member?(set_with_zero, 0)
        true

    A set with a `2` is stored as `bits = 4`,
    because the bit at `2` is set, so the element `2` is present:

        iex> set_with_two = NaturalSet.new([2])
        iex> set_with_two.bits
        4
        iex> NaturalSet.member?(set_with_two, 2)
        true

    A set with the elements `0` and `1` is stored as `bits = 3`,
    because `3` is `0b11`, so the bits at `0` and `1` are set:

        iex> set_with_zero_and_one = NaturalSet.new([0, 1])
        #NaturalSet<[0, 1]>
        iex> set_with_zero_and_one.bits
        3

    `NaturalSet`s can also be constructed starting from other collection-type data
    structures: for example, see `NaturalSet.new/1` or `Enum.into/2`.

    All the content of an `NaturalSet` is represented by a single integer,
    which in Elixir is limited only by available memory.
    Using an integer as a bit vector allows set operations like union and intersection
    to be implemented using fast bitwise operators.
    See the source code of `NaturalSet.union` and `NaturalSet.intersection`.

    A bit vector is efficient only for storing sets of small integers,
    or high-density sets where a large percentage of the possible elements are present.
    The memory usage is proportional only to the largest element stored,
    not to the number of elements present.
    If the largest element in a set is 1_000_000,
    the raw bits will take 125_000 bytes (⅛),
    regardless of the number of elements in the set.

    This package was inspired by the `intset` example from chapter 6 of
    _The Go Programming Language_, by Alan. A. A. Donovan and Brian W. Kernighan.
  """

  use Bitwise, only_operators: true

  defstruct bits: 0

  @doc """
  Returns a new empty `NaturalSet`.

  ## Example

      iex> NaturalSet.new()
      #NaturalSet<[]>

  """
  def new, do: %NaturalSet{}

  @doc """
  Creates a set from an enumerable.

  ## Examples

      iex> NaturalSet.new([10, 5, 7])
      #NaturalSet<[5, 7, 10]>
      iex> NaturalSet.new(3..7)
      #NaturalSet<[3, 4, 5, 6, 7]>
      iex> NaturalSet.new([3, 3, 3, 2, 2, 1])
      #NaturalSet<[1, 2, 3]>

  """
  def new(enumerable) do
    enumerable |> Enum.into(NaturalSet.new())
  end

  @doc """
  Creates a set from an enumerable via the transformation function.

  ## Examples

      iex> NaturalSet.new([1, 3, 1], fn x -> 2 * x end)
      #NaturalSet<[2, 6]>

  """
  def new(enumerable, transform) when is_function(transform, 1) do
    enumerable |> Stream.map(transform) |> new
  end

  @doc """
  Inserts `element` into `natural_set` if `natural_set` doesn't already contain it.

  ## Examples

      iex> NaturalSet.put(NaturalSet.new([1, 2, 3]), 3)
      #NaturalSet<[1, 2, 3]>
      iex> NaturalSet.put(NaturalSet.new([1, 2, 3]), 4)
      #NaturalSet<[1, 2, 3, 4]>

  """
  def put(%NaturalSet{bits: bits}, element) when is_integer(element) and element >= 0 do
    %NaturalSet{bits: 1 <<< element ||| bits}
  end

  @doc """
  Checks if `natural_set` contains `element`.

  ## Examples

      iex> NaturalSet.member?(NaturalSet.new([1, 2, 3]), 2)
      true
      iex> NaturalSet.member?(NaturalSet.new([1, 2, 3]), 4)
      false

  """
  def member?(%NaturalSet{bits: bits}, element) when is_integer(element) and element >= 0 do
    (bits >>> element &&& 1) == 1
  end

  @doc """
  Returns a new set which is a copy of `natural_set` without `element`.

  ## Examples

      iex> natural_set = NaturalSet.new([1, 2, 3])
      iex> NaturalSet.delete(natural_set, 4)
      #NaturalSet<[1, 2, 3]>
      iex> NaturalSet.delete(natural_set, 2)
      #NaturalSet<[1, 3]>

  """
  def delete(natural_set, element) when is_integer(element) and element >= 0 do
    if member?(natural_set, element) do
      new_bits = (1 <<< element) ^^^ natural_set.bits
      %NaturalSet{bits: new_bits}
    else
      # return unchanged
      natural_set
    end
  end

  @doc """
  Checks if two sets are equal.

  ## Examples

      iex> NaturalSet.equal?(NaturalSet.new([1, 2]), NaturalSet.new([2, 1, 1]))
      true
      iex> NaturalSet.equal?(NaturalSet.new([1, 2]), NaturalSet.new([3, 4]))
      false

  """
  def equal?(%NaturalSet{bits: bits1}, %NaturalSet{bits: bits2}) do
    bits1 == bits2
  end

  @doc """
  Returns a set containing only members that `natural_set1` and `natural_set2` have in common.

  ## Examples

      iex> NaturalSet.intersection(NaturalSet.new([1, 2]), NaturalSet.new([2, 3, 4]))
      #NaturalSet<[2]>

      iex> NaturalSet.intersection(NaturalSet.new([1, 2]), NaturalSet.new([3, 4]))
      #NaturalSet<[]>

  """
  def intersection(%NaturalSet{bits: bits1}, %NaturalSet{bits: bits2}) do
    %NaturalSet{bits: bits1 &&& bits2}
  end

  @doc """
  Returns a set containing all members of `natural_set1` and `natural_set2`.

  ## Examples

      iex> NaturalSet.union(NaturalSet.new([1, 2]), NaturalSet.new([2, 3, 4]))
      #NaturalSet<[1, 2, 3, 4]>

  """
  def union(%NaturalSet{bits: bits1}, %NaturalSet{bits: bits2}) do
    %NaturalSet{bits: bits1 ||| bits2}
  end

  @doc """
  Returns a new set like `natural_set1` without the members of `natural_set2`.

  ## Examples

      iex> NaturalSet.difference(NaturalSet.new([1, 2]), NaturalSet.new([2, 3, 4]))
      #NaturalSet<[1]>

  """
  def difference(%NaturalSet{bits: bits1}, %NaturalSet{bits: bits2}) do
    %NaturalSet{bits: bits1 &&& bits2 ^^^ bits1}
  end

  @doc """
  Checks if `natural_set1`'s members are all contained in `natural_set2`.

  This function checks if `natural_set1` is a subset of `natural_set2`.

  ## Examples

      iex> NaturalSet.subset?(NaturalSet.new([1, 2]), NaturalSet.new([1, 2, 3]))
      true
      iex> NaturalSet.subset?(NaturalSet.new([1, 2, 3]), NaturalSet.new([1, 2]))
      false

  """
  def subset?(natural_set1, natural_set2) do
    difference(natural_set1, natural_set2).bits == 0
  end

  @doc """
  Checks if `natural_set1` and `natural_set2` have no members in common.

  ## Examples

      iex> NaturalSet.disjoint?(NaturalSet.new([1, 2]), NaturalSet.new([3, 4]))
      true
      iex> NaturalSet.disjoint?(NaturalSet.new([1, 2]), NaturalSet.new([2, 3]))
      false

  """
  def disjoint?(natural_set1, natural_set2) do
    intersection(natural_set1, natural_set2).bits == 0
  end

  @doc """
  Returns the number of elements in `natural_set`.
  The corresponding function in `MapSet` is `size`.
  This function is named `length` because it traverses the `natural_set`,
  so it runs in O(n) time.

  ## Example

      iex> NaturalSet.length(NaturalSet.new([10, 20, 30]))
      3

  """
  def length(%NaturalSet{bits: bits}) do
    count_ones(bits, 0)
  end

  defp count_ones(0, count), do: count

  defp count_ones(bits, count) do
    count = count + (bits &&& 1)
    count_ones(bits >>> 1, count)
  end

  @doc """
  Returns a stream function yielding the elements of `natural_set` one by one in ascending order.
  The stream lazily traverses the bits of the `natural_set` as needed.

  ## Examples

      iex> my_stream = NaturalSet.new([10, 5, 7]) |> NaturalSet.stream
      iex> my_stream |> is_function
      true
      iex> my_stream |> Stream.map(&(&1 * 10)) |> Enum.to_list
      [50, 70, 100]

  """
  def stream(%NaturalSet{bits: bits}) do
    Stream.unfold({bits, 0}, &next_one/1)
  end

  defp next_one({0, _index}), do: nil

  defp next_one({bits, index}) when (bits &&& 1) == 1 do
    # LSB is one: return {next_element, new_accumulator_tuple}
    {index, {bits >>> 1, index + 1}}
  end

  defp next_one({bits, index}) do
    # LSB is 0: shift bits; increment index; try again
    next_one({bits >>> 1, index + 1})
  end

  @doc """
  Returns a list containing all members of `natural_set` in ascending order.

  ## Examples

      iex> NaturalSet.new([2, 3, 1]) |> NaturalSet.to_list
      [1, 2, 3]

  """
  def to_list(natural_set) do
    natural_set |> stream |> Enum.to_list()
  end

  defimpl Enumerable do
    def count(natural_set) do
      {:ok, NaturalSet.length(natural_set)}
    end

    def member?(natural_set, val) do
      {:ok, NaturalSet.member?(natural_set, val)}
    end

    def slice(_set) do
      {:error, __MODULE__}
    end

    def reduce(natural_set, acc, fun) do
      Enumerable.List.reduce(NaturalSet.to_list(natural_set), acc, fun)
    end
  end

  defimpl Collectable do
    def into(original) do
      collector_fun = fn
        set, {:cont, elem} -> NaturalSet.put(set, elem)
        set, :done -> set
        _set, :halt -> :ok
      end

      {original, collector_fun}
    end
  end

  defimpl Inspect do
    import Inspect.Algebra

    def inspect(natural_set, opts) do
      concat(["#NaturalSet<", Inspect.List.inspect(NaturalSet.to_list(natural_set), opts), ">"])
    end
  end
end
