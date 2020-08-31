defmodule NaturalSetTest do
  use ExUnit.Case, async: true
  doctest NaturalSet

  import NaturalSet

  test "new/1" do
    assert %NaturalSet{bits: 0b1110} == NaturalSet.new([1, 2, 3])
  end

  test "new/2" do
    result = NaturalSet.new([1, 2, 3], &(&1 * 10))
    assert result == NaturalSet.new([10, 20, 30])
  end

  test "to_list/1 -> []" do
    result = NaturalSet.new() |> to_list()
    assert result == []
  end

  test "to_list/1 -> [0]" do
    result = %NaturalSet{bits: 1} |> to_list()
    assert result == [0]
  end

  test "to_list/1 -> [0, 1, 2, 3]" do
    result = %NaturalSet{bits: 0b1111} |> to_list()
    assert result == [0, 1, 2, 3]
  end

  test "to_list/1 -> [1, 100]" do
    bigint = round(:math.pow(2, 100)) + 2

    result =
      %NaturalSet{bits: bigint}
      |> to_list()

    assert result == [1, 100]
  end

  test "put/1" do
    [
      {NaturalSet.new(), 0, [0]},
      {NaturalSet.new(), 1, [1]},
      {NaturalSet.new(), 1000, [1000]},
      {%NaturalSet{bits: 0xF0}, 9, [4, 5, 6, 7, 9]}
    ]
    |> Enum.each(fn {initial, element, wanted} ->
      result = initial |> put(element) |> to_list

      assert result == wanted,
             "{#{inspect(initial)}, #{element}, #{inspect(wanted)}} -> #{inspect(result)}"
    end)
  end

  test "member/1" do
    refute NaturalSet.new() |> NaturalSet.member?(0)
    assert [0] |>NaturalSet.new() |> NaturalSet.member?(0)
    assert [1, 1000] |> NaturalSet.new() |> NaturalSet.member?(1000)
    refute [1, 1000] |> NaturalSet.new() |> NaturalSet.member?(0)
  end

  # the following tests were adapted from elixir/map_set_test.exs

  test "equal?/2" do
    assert NaturalSet.equal?(NaturalSet.new(), NaturalSet.new())
    refute NaturalSet.equal?(NaturalSet.new(1..20), NaturalSet.new(2..21))
    assert NaturalSet.equal?(NaturalSet.new(1..120), NaturalSet.new(1..120))
  end

  test "union/2" do
    result = NaturalSet.union(NaturalSet.new([1, 3, 4]), NaturalSet.new())
    assert NaturalSet.equal?(result, NaturalSet.new([1, 3, 4]))

    result = NaturalSet.union(NaturalSet.new(5..15), NaturalSet.new(10..25))
    assert NaturalSet.equal?(result, NaturalSet.new(5..25))

    result = NaturalSet.union(NaturalSet.new(1..120), NaturalSet.new(1..100))
    assert NaturalSet.equal?(result, NaturalSet.new(1..120))
  end

  test "intersection/2" do
    result = NaturalSet.intersection(NaturalSet.new(), NaturalSet.new(1..21))
    assert NaturalSet.equal?(result, NaturalSet.new())

    result = NaturalSet.intersection(NaturalSet.new(1..21), NaturalSet.new(4..24))
    assert NaturalSet.equal?(result, NaturalSet.new(4..21))

    result = NaturalSet.intersection(NaturalSet.new(2..100), NaturalSet.new(1..120))
    assert NaturalSet.equal?(result, NaturalSet.new(2..100))
  end

  test "difference/2" do
    result = NaturalSet.difference(NaturalSet.new(2..20), NaturalSet.new())
    assert NaturalSet.equal?(result, NaturalSet.new(2..20))

    result = NaturalSet.difference(NaturalSet.new(2..20), NaturalSet.new(1..21))
    assert NaturalSet.equal?(result, NaturalSet.new())

    result = NaturalSet.difference(NaturalSet.new(1..101), NaturalSet.new(2..100))
    assert NaturalSet.equal?(result, NaturalSet.new([1, 101]))
  end

  test "disjoint?/2" do
    assert NaturalSet.disjoint?(NaturalSet.new(), NaturalSet.new())
    assert NaturalSet.disjoint?(NaturalSet.new(1..6), NaturalSet.new(8..20))
    refute NaturalSet.disjoint?(NaturalSet.new(1..6), NaturalSet.new(5..15))
    refute NaturalSet.disjoint?(NaturalSet.new(1..120), NaturalSet.new(1..6))
  end

  test "subset?/2" do
    assert NaturalSet.subset?(NaturalSet.new(), NaturalSet.new())
    assert NaturalSet.subset?(NaturalSet.new(1..6), NaturalSet.new(1..10))
    assert NaturalSet.subset?(NaturalSet.new(1..6), NaturalSet.new(1..120))
    refute NaturalSet.subset?(NaturalSet.new(1..120), NaturalSet.new(1..6))
  end

  test "delete/2" do
    result = NaturalSet.delete(NaturalSet.new(), 1)
    assert NaturalSet.equal?(result, NaturalSet.new())

    result = NaturalSet.delete(NaturalSet.new(1..4), 5)
    assert NaturalSet.equal?(result, NaturalSet.new(1..4))

    result = NaturalSet.delete(NaturalSet.new(1..4), 1)
    assert NaturalSet.equal?(result, NaturalSet.new(2..4))

    result = NaturalSet.delete(NaturalSet.new(1..4), 2)
    assert NaturalSet.equal?(result, NaturalSet.new([1, 3, 4]))
  end

  # the following test was adapted from the size/1 test in elixir/map_set_test.exs,
  # but here the function is length/1 because it runs in O(n) time

  test "length/1" do
    assert NaturalSet.length(NaturalSet.new()) == 0
    assert NaturalSet.length(NaturalSet.new(5..15)) == 11
    assert NaturalSet.length(NaturalSet.new(2..100)) == 99
  end

  test "Enumerable protocol" do
    # given, total, first, second, has_3, reversed
    [
      {[], 0, nil, nil, false, []},
      {[0], 0, 0, nil, false, [0]},
      {[1], 1, 1, nil, false, [1]},
      {[2, 3, 4], 9, 2, 3, true, [4, 3, 2]},
      {[3, 1000], 1003, 3, 1000, true, [1000, 3]}
    ]
    |> Enum.each(fn {given, total, first, second, has_3, reversed} ->
      set = given |> NaturalSet.new()
      assert total == set |> Enum.sum()
      assert first == set |> Enum.at(0)
      assert second == set |> Enum.at(1)
      assert has_3 == set |> Enum.member?(3)
      assert reversed == set |> Enum.reverse()
    end)
  end

  test "Collectable protocol" do
    [
      [],
      [0],
      [1],
      [1, 2, 3],
      [1, 1000]
    ]
    |> Enum.each(fn given ->
      result = given |> Enum.into(NaturalSet.new()) |> to_list
      assert result == given, "{#{inspect(given)}} -> #{inspect(result)}"
    end)
  end

  test "stream/1" do
    result =
      1..5
      |> NaturalSet.new()
      |> NaturalSet.stream()
      |> Stream.map(&(&1 * 2))
      |> Enum.to_list()

    assert result == [2, 4, 6, 8, 10]
  end
end
