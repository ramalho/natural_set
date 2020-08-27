defmodule BitOps do
  @moduledoc """
  BitOps provides bit-level operations on integers.
  This is a low level utility module to support `NaturalSet`.

  All the functions take an integer as the first argument;
  most return new integers by flipping bits on the first argument,
  returning the value of a specific bit, or finding bits set to `1`.
  """

  use Bitwise, only_operators: true

  @doc """
  Count the bits of value `1` in an integer.

  ## Examples

      iex> BitOps.count_ones(0)
      0
      iex> BitOps.count_ones(3)
      2
      iex> BitOps.count_ones(0b111_0000_1111)
      7
  """
  @spec count_ones(non_neg_integer()) :: non_neg_integer()
  def count_ones(bigint) when is_integer(bigint) and bigint >= 0 do
    count_ones(bigint, 0)
  end

  defp count_ones(0, count), do: count

  defp count_ones(bigint, count) do
    count = count + (bigint &&& 1)
    count_ones(bigint >>> 1, count)
  end

  @doc """
  Get the value of the bit at the `index`.

  ## Examples

      iex> BitOps.get_bit(0b101, 0)
      1
      iex> BitOps.get_bit(0b101, 1)
      0
      iex> BitOps.get_bit(0b101, 99)
      0
  """
  @spec get_bit(integer(), integer()) :: 0 | 1
  def get_bit(bigint, index) do
    bigint >>> index &&& 1
  end

  @doc """
  Set the bit at `index` to `1`.

  ## Examples

      iex> BitOps.set_bit(0b101, 1)
      7
      iex> BitOps.set_bit(0, 8)
      256
  """
  @spec set_bit(integer(), integer()) :: integer()
  def set_bit(bigint, index) do
    1 <<< index ||| bigint
  end

  @doc """
  Set the bit at `index` to `0`.

  ## Examples

      iex> BitOps.unset_bit(0b101, 0)
      4
      iex> BitOps.unset_bit(0b111, 2)
      3
  """
  @spec unset_bit(integer(), integer()) :: integer()
  def unset_bit(bigint, index) do
    if get_bit(bigint, index) == 1 do
      (1 <<< index) ^^^ bigint
    else
      bigint
    end
  end

  @doc """
  Return a list of all indexes with bit value `1`.

  ## Examples

      iex> BitOps.list_ones(0)
      []
      iex> BitOps.list_ones(0b1011)
      [0, 1, 3]
  """
  def list_ones(bigint) when is_integer(bigint) and bigint >= 0 do
    list_ones(bigint, 0, [])
  end

  defp list_ones(0, _index, list), do: Enum.reverse(list)

  defp list_ones(bigint, index, list) when (bigint &&& 1) == 1 do
    list_ones(bigint >>> 1, index + 1, [index | list])
  end

  defp list_ones(bigint, index, list) do
    list_ones(bigint >>> 1, index + 1, list)
  end

  @doc """
  Returns a stream function yielding the indexes with bit value `1`.
  The stream lazily traverses the bits of the integer as needed.

  ## Examples

      iex> my_stream = BitOps.stream_ones(0b1010_1110)
      iex> my_stream |> is_function
      true
      iex> my_stream |> Enum.reverse
      [7, 5, 3, 2, 1]

  """
  def stream_ones(bigint) when is_integer(bigint) and bigint >= 0 do
    Stream.unfold({bigint, 0}, &next_one/1)
  end

  defp next_one({0, _index}), do: nil

  defp next_one({bigint, index}) when (bigint &&& 1) == 1 do
    # Return {next_element, new_accumulator}
    {index, {bigint >>> 1, index + 1}}
  end

  defp next_one({bigint, index}) do
    # Shift bigint, increment index, try again
    next_one({bigint >>> 1, index + 1})
  end
end
