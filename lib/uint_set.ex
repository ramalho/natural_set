defmodule UintSet do
  @moduledoc """
    Functions that work on sets of small integers >= 0.

    `UintSet` is an alternative set type in Elixir
    emulating the `MapSet` interface as closely as possible.
    Many of the `UintSet` doctests and unit tests were adapted from `MapSet`.
    `UintSet` illustrates the construction of a functional data structure from scratch,
    implementing the `Inspect`, `Enumerable`, and `Collectable` protocols.

    An `UintSet` can contain only non-negative integers.
    By definition, sets contain unique elements.
    Trying to insert a duplicate is a no-op:

        iex> uint_set = UintSet.new()
        #UintSet<[]>
        iex> uint_set = UintSet.put(uint_set, 3)
        #UintSet<[3]>
        iex> uint_set |> UintSet.put(2) |> UintSet.put(2)
        #UintSet<[2, 3]>

    `UintSet.new/1` accepts an enumerable of elements:

        iex> UintSet.new(1..5)
        #UintSet<[1, 2, 3, 4, 5]>

    An `UintSet` is represented internally using the `%UintSet{}` struct.
    This struct can be used whenever there's a need to pattern match on something being an `UintSet`:

        iex> match?(%UintSet{}, UintSet.new())
        true

    The `%UintSet{}` struct contains a single field—`bits`—
    an integer which is used as a bit vector where each bit set to `1` represents
    a number present in the set.

    An empty set is stored as `bits = 0`:

        iex> empty = UintSet.new()
        iex> empty.bits
        0
        iex> UintSet.member?(empty, 0)
        false

    A set containing just a `0` is stored as `bits = 1`,
    because the bit at `0` is set, so the element `0` is present:

        iex> set_with_zero = UintSet.new([0])
        iex> set_with_zero.bits
        1
        iex> UintSet.member?(set_with_zero, 0)
        true

    A set with a `2` is stored as `bits = 4`,
    because the bit at `2` is set, so the element `2` is present:

        iex> set_with_two = UintSet.new([2])
        iex> set_with_two.bits
        4
        iex> UintSet.member?(set_with_two, 2)
        true

    A set with the elements `0` and `1` is stored as `bits = 3`,
    because `3` is `0b11`, so the bits at `0` and `1` are set:

        iex> set_with_zero_and_one = UintSet.new([0, 1])
        #UintSet<[0, 1]>
        iex> set_with_zero_and_one.bits
        3

    The `UintSet.new/1` function also accepts a keyword argument
    setting the initial value of the `bits` field:

        iex> UintSet.new(bits: 13)
        #UintSet<[0, 2, 3]>

    This is easier to understand using base 2 notation for the argument:

        iex> UintSet.new(bits: 0b1101)
        #UintSet<[0, 2, 3]>

    `UintSet`s can also be constructed starting from other collection-type data
    structures: for example, see `UintSet.new/1` or `Enum.into/2`.

    All the content of an `UintSet` is represented by a single integer,
    which in Elixir is limited only by available memory.
    Using an integer as a bit vector allows set operations like union and intersection
    to be implemented using fast bitwise operators.
    See the source code of `UintSet.union` and `UintSet.intersection`.

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

  import BitOps

  defstruct bits: 0

  @doc """
  Returns a new empty `UintSet`.

  ## Example

      iex> UintSet.new()
      #UintSet<[]>

  """
  def new, do: %UintSet{}

  @doc """
  Returns a new `UintSet` reading the given integer as a bit pattern.

  ## Examples

      iex> UintSet.new(bits: 0)
      #UintSet<[]>
      iex> UintSet.new(bits: 1)
      #UintSet<[0]>
      iex> UintSet.new(bits: 2)
      #UintSet<[1]>
      iex> UintSet.new(bits: 3)
      #UintSet<[0, 1]>
      iex> UintSet.new(bits: 0b111010)
      #UintSet<[1, 3, 4, 5]>

  """
  def new(bits: bigint) when is_integer(bigint) and bigint >= 0 do
    %UintSet{bits: bigint}
  end

  @doc """
  Creates a set from an enumerable.

  ## Examples

      iex> UintSet.new([10, 5, 7])
      #UintSet<[5, 7, 10]>
      iex> UintSet.new(3..7)
      #UintSet<[3, 4, 5, 6, 7]>
      iex> UintSet.new([3, 3, 3, 2, 2, 1])
      #UintSet<[1, 2, 3]>

  """
  def new(enumerable) do
    Enum.reduce(enumerable, %UintSet{}, &UintSet.put(&2, &1))
  end

  @doc """
  Creates a set from an enumerable via the transformation function.

  ## Examples

      iex> UintSet.new([1, 3, 1], fn x -> 2 * x end)
      #UintSet<[2, 6]>

  """
  def new(enumerable, transform) when is_function(transform, 1) do
    enumerable
    |> Stream.map(transform)
    |> new
  end

  @doc """
  Deletes `value` from `uint_set`.

  Returns a new set which is a copy of `uint_set` but without `value`.

  ## Examples

      iex> uint_set = UintSet.new([1, 2, 3])
      iex> UintSet.delete(uint_set, 4)
      #UintSet<[1, 2, 3]>
      iex> UintSet.delete(uint_set, 2)
      #UintSet<[1, 3]>

  """
  def delete(%UintSet{bits: bits}, value) do
    %UintSet{bits: unset_bit(bits, value)}
  end

  @doc """
  Returns a new set like `uint_set1` without the members of `uint_set2`.

  ## Examples

      iex> UintSet.difference(UintSet.new([1, 2]), UintSet.new([2, 3, 4]))
      #UintSet<[1]>

  """
  def difference(%UintSet{bits: bits1}, %UintSet{bits: bits2}) do
    %UintSet{bits: bits1 &&& bits2 ^^^ bits1}
  end

  @doc """
  Checks if `uint_set1` and `uint_set2` have no members in common.

  ## Examples

      iex> UintSet.disjoint?(UintSet.new([1, 2]), UintSet.new([3, 4]))
      true
      iex> UintSet.disjoint?(UintSet.new([1, 2]), UintSet.new([2, 3]))
      false

  """
  def disjoint?(%UintSet{bits: bits1}, %UintSet{bits: bits2}) do
    (bits1 &&& bits2) == 0
  end

  @doc """
  Checks if two sets are equal.

  ## Examples

      iex> UintSet.equal?(UintSet.new([1, 2]), UintSet.new([2, 1, 1]))
      true
      iex> UintSet.equal?(UintSet.new([1, 2]), UintSet.new([3, 4]))
      false

  """
  def equal?(%UintSet{bits: bits1}, %UintSet{bits: bits2}) do
    bits1 == bits2
  end

  @doc """
  Returns a set containing only members that `uint_set1` and `uint_set2` have in common.

  ## Examples

      iex> UintSet.intersection(UintSet.new([1, 2]), UintSet.new([2, 3, 4]))
      #UintSet<[2]>

      iex> UintSet.intersection(UintSet.new([1, 2]), UintSet.new([3, 4]))
      #UintSet<[]>

  """
  def intersection(%UintSet{bits: bits1}, %UintSet{bits: bits2}) do
    %UintSet{bits: bits1 &&& bits2}
  end

  @doc """
  Returns the number of elements in `uint_set`.
  This function is named `length` because it needs to traverse the `uint_set`,
  so it runs in O(n) time. The corresponding function in `MapSet` is `size`.

  ## Example

      iex> UintSet.length(UintSet.new([10, 20, 30]))
      3

  """
  def length(%UintSet{bits: bits}) do
    bits |> count_ones
  end

  @doc """
  Checks if `uint_set` contains `value`.

  ## Examples

      iex> UintSet.member?(UintSet.new([1, 2, 3]), 2)
      true
      iex> UintSet.member?(UintSet.new([1, 2, 3]), 4)
      false

  """
  def member?(%UintSet{bits: bits}, value) do
    get_bit(bits, value) == 1
  end

  @doc """
  Inserts `value` into `uint_set` if `uint_set` doesn't already contain it.

  ## Examples

      iex> UintSet.put(UintSet.new([1, 2, 3]), 3)
      #UintSet<[1, 2, 3]>
      iex> UintSet.put(UintSet.new([1, 2, 3]), 4)
      #UintSet<[1, 2, 3, 4]>

  """
  def put(%UintSet{bits: bits}, value) do
    %UintSet{bits: set_bit(bits, value)}
  end

  @doc """
  Returns a stream function yielding the elements of `uint_set` one by one in ascending order.
  The stream lazily traverses the bits of the `uint_set` as needed.

  ## Examples

      iex> my_stream = UintSet.new([10, 5, 7]) |> UintSet.stream
      iex> my_stream |> is_function
      true
      iex> my_stream |> Stream.map(&(&1 * 10)) |> Enum.to_list
      [50, 70, 100]

  """
  def stream(%UintSet{bits: bits}) do
    stream_ones(bits)
  end

  @doc """
  Checks if `uint_set1`'s members are all contained in `uint_set2`.

  This function checks if `uint_set1` is a subset of `uint_set2`.

  ## Examples

      iex> UintSet.subset?(UintSet.new([1, 2]), UintSet.new([1, 2, 3]))
      true
      iex> UintSet.subset?(UintSet.new([1, 2, 3]), UintSet.new([1, 2]))
      false

  """
  def subset?(uint_set1, uint_set2) do
    difference(uint_set1, uint_set2).bits == 0
  end

  @doc """
  Returns a list containing all members of `uint_set` in ascending order.

  ## Examples

      iex> UintSet.to_list(UintSet.new([2, 3, 1]))
      [1, 2, 3]

  """
  def to_list(%UintSet{bits: bits}) do
    bits |> list_ones
  end

  @doc """
  Returns a set containing all members of `uint_set1` and `uint_set2`.

  ## Examples

      iex> UintSet.union(UintSet.new([1, 2]), UintSet.new([2, 3, 4]))
      #UintSet<[1, 2, 3, 4]>

  """
  def union(%UintSet{bits: bits1}, %UintSet{bits: bits2}) do
    %UintSet{bits: bits1 ||| bits2}
  end

  defimpl Enumerable do
    def count(uint_set) do
      {:ok, UintSet.length(uint_set)}
    end

    def member?(uint_set, val) do
      {:ok, UintSet.member?(uint_set, val)}
    end

    def slice(_set) do
      {:error, __MODULE__}
    end

    def reduce(uint_set, acc, fun) do
      Enumerable.List.reduce(UintSet.to_list(uint_set), acc, fun)
    end
  end

  defimpl Collectable do
    def into(original) do
      collector_fun = fn
        set, {:cont, elem} -> UintSet.put(set, elem)
        set, :done -> set
        _set, :halt -> :ok
      end

      {original, collector_fun}
    end
  end

  defimpl Inspect do
    import Inspect.Algebra

    def inspect(uint_set, opts) do
      concat(["#UintSet<", Inspect.List.inspect(UintSet.to_list(uint_set), opts), ">"])
    end
  end
end
