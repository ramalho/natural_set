defmodule BitOpsTest do
  use ExUnit.Case, async: true
  doctest BitOps

  import BitOps

  def pow(base, exp) when base >= 0 do
    pow(base, exp, 1)
  end

  defp pow(_, 0, _), do: 1

  defp pow(base, 1, res), do: base * res

  defp pow(base, exp, res) do
    res = res * base
    pow(base, exp - 1, res)
  end

  test "count_ones -> 0" do
    assert count_ones(0) == 0
  end

  test "count_ones -> 1" do
    [1, 0b10, 0b100, pow(2, 100)]
    |> Enum.each(fn n ->
      assert count_ones(n) == 1
    end)
  end

  test "count_ones -> 2" do
    [0b11, 0b101, 0b110, pow(2, 100) + 1]
    |> Enum.each(fn n ->
      assert count_ones(n) == 2
    end)
  end

  test "count_ones -> 3" do
    [0b111, 0b1011, 0b1101, 0b1110, pow(2, 100) + 3]
    |> Enum.each(fn n ->
      assert count_ones(n) == 3
    end)
  end

  test "count_ones -> many" do
    [{0b1111_1111_1111, 12}, {pow(2, 100) - 1, 100}]
    |> Enum.each(fn {bigint, count} ->
      assert count_ones(bigint) == count
    end)
  end

  test "get_bit" do
    [
      {0, 0, 0},
      {0, 1, 0},
      {0, 100, 0},
      {1, 0, 1},
      {1, 1, 0},
      {0b10, 0, 0},
      {0b10, 1, 1},
      {0b1_0101_0101, 2, 1},
      {0b1_0101_0101, 3, 0},
      {0b1_0101_0101, 7, 0},
      {0b1_0101_0101, 8, 1},
      {pow(2, 64), 0, 0},
      {pow(2, 64), 64, 1},
      {pow(2, 64) - 1, 0, 1},
      {pow(2, 64) - 1, 1, 1},
      {pow(2, 64) - 1, 63, 1}
    ]
    |> Enum.each(fn {bigint, index, wanted} ->
      actual = get_bit(bigint, index)
      assert actual == wanted, "{#{bigint}, #{index}, #{wanted}} -> #{actual}"
    end)
  end

  test "set_bit" do
    [
      {0, 0, 1},
      {1, 0, 1},
      {0, 1, 0b10},
      {1, 1, 0b11},
      {0, 8, 0b1_0000_0000},
      {1, 8, 0b1_0000_0001},
      {0b10, 0, 0b11},
      {0b11, 1, 0b11},
      {0b1_0101_0101, 1, 0b1_0101_0111},
      {0b1_0101_0101, 2, 0b1_0101_0101},
      {0b1_0101_0101, 7, 0b1_1101_0101},
      {0b1_0101_0101, 9, 0b11_0101_0101},
      {pow(2, 64), 0, pow(2, 64) + 1},
      {pow(2, 64), 64, pow(2, 64)},
      {pow(2, 64), 65, pow(2, 65) + pow(2, 64)}
    ]
    |> Enum.each(fn {bigint, index, wanted} ->
      actual = set_bit(bigint, index)
      assert actual == wanted, "{#{bigint}, #{index}, #{wanted}} -> #{actual}"
    end)
  end

  test "unset_bit" do
    [
      {0, 0, 0},
      {1, 0, 0},
      {0, 8, 0},
      {0b10, 0, 0b10},
      {0b11, 1, 0b01},
      {0b1_0101_0101, 0, 0b1_0101_0100},
      {0b1_0101_0101, 1, 0b1_0101_0101},
      {0b1_0101_0101, 2, 0b1_0101_0001},
      {0b1_0101_0101, 8, 0b0_0101_0101},
      {0b1_0101_0101, 9, 0b1_0101_0101},
      {pow(2, 64), 0, pow(2, 64)},
      {pow(2, 64) + 1, 0, pow(2, 64)},
      {pow(2, 64), 64, 0}
    ]
    |> Enum.each(fn {bigint, index, wanted} ->
      actual = unset_bit(bigint, index)
      assert actual == wanted, "{#{bigint}, #{index}, #{wanted}} -> #{actual}"
    end)
  end

  @ones_fixture [
    {0, []},
    {1, [0]},
    {0b10, [1]},
    {0b11, [0, 1]},
    {0b101, [0, 2]},
    {0b111, [0, 1, 2]},
    {0b1010_1010, [1, 3, 5, 7]},
    {0b1_0101_0101, [0, 2, 4, 6, 8]},
    {0b1111_1111, 0..7 |> Enum.to_list()},
    {0b1_1111_1110, 1..8 |> Enum.to_list()}
  ]

  test "stream_ones" do
    @ones_fixture
    |> Enum.each(fn {bigint, wanted} ->
      stream = stream_ones(bigint)
      assert is_function(stream, 2)
      actual = Enum.to_list(stream)
      assert actual == wanted, "{#{bigint}, #{inspect(wanted)}} -> #{inspect(actual)}"
    end)
  end
end
