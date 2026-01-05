defmodule LeidenfoldTest do
  use ExUnit.Case
  doctest Leidenfold

  describe "detect/3" do
    test "detects communities with modularity" do
      edges = [{0, 1}, {1, 2}, {2, 0}, {3, 4}, {4, 5}, {5, 3}, {2, 3}]
      {sources, targets} = Enum.unzip(edges)

      {:ok, result} = Leidenfold.detect(sources, targets, objective: :modularity)

      assert is_list(result.membership)
      assert length(result.membership) == 6
      assert result.n_communities == 2
    end

    test "detects communities with CPM" do
      edges = [{0, 1}, {1, 2}, {2, 0}, {3, 4}, {4, 5}, {5, 3}, {2, 3}]
      {sources, targets} = Enum.unzip(edges)

      {:ok, result} = Leidenfold.detect(sources, targets, objective: :cpm, resolution: 0.5)

      assert is_list(result.membership)
      assert result.n_communities >= 1
    end

    test "handles weighted edges" do
      sources = [0, 1, 2]
      targets = [1, 2, 0]
      weights = [1.0, 2.0, 1.5]

      {:ok, result} = Leidenfold.detect(sources, targets, weights: weights)

      assert is_list(result.membership)
      assert length(result.membership) == 3
    end

    test "uses seed for reproducibility" do
      edges = [{0, 1}, {1, 2}, {2, 0}, {3, 4}, {4, 5}, {5, 3}, {2, 3}]
      {sources, targets} = Enum.unzip(edges)

      {:ok, result1} = Leidenfold.detect(sources, targets, seed: 42)
      {:ok, result2} = Leidenfold.detect(sources, targets, seed: 42)

      assert result1.membership == result2.membership
    end
  end

  describe "detect_from_edges/2" do
    test "works with edge tuples" do
      edges = [{0, 1}, {1, 2}, {2, 0}]

      {:ok, result} = Leidenfold.detect_from_edges(edges)

      assert is_list(result.membership)
      assert length(result.membership) == 3
    end
  end

  describe "detect_from_weighted_edges/2" do
    test "works with weighted edge tuples" do
      edges = [{0, 1, 1.0}, {1, 2, 2.0}, {2, 0, 1.5}]

      {:ok, result} = Leidenfold.detect_from_weighted_edges(edges)

      assert is_list(result.membership)
      assert length(result.membership) == 3
    end
  end

  describe "detect!/3" do
    test "returns result directly" do
      edges = [{0, 1}, {1, 2}, {2, 0}]
      {sources, targets} = Enum.unzip(edges)

      result = Leidenfold.detect!(sources, targets)

      assert is_map(result)
      assert is_list(result.membership)
    end
  end
end
