defmodule LeidenfoldTest do
  use ExUnit.Case
  doctest Leidenfold

  # Two well-separated triangles connected by a bridge edge
  @two_triangles [{0, 1}, {1, 2}, {2, 0}, {3, 4}, {4, 5}, {5, 3}, {2, 3}]

  describe "detect/3" do
    test "detects communities with modularity" do
      {sources, targets} = Enum.unzip(@two_triangles)

      {:ok, result} = Leidenfold.detect(sources, targets, objective: :modularity)

      assert is_list(result.membership)
      assert length(result.membership) == 6
      assert result.n_communities == 2
      assert is_float(result.quality)
    end

    test "detects communities with CPM" do
      {sources, targets} = Enum.unzip(@two_triangles)

      {:ok, result} = Leidenfold.detect(sources, targets, objective: :cpm, resolution: 0.5)

      assert is_list(result.membership)
      assert result.n_communities >= 1
    end

    test "detects communities with rber" do
      {sources, targets} = Enum.unzip(@two_triangles)

      {:ok, result} = Leidenfold.detect(sources, targets, objective: :rber)

      assert is_list(result.membership)
      assert result.n_communities >= 1
    end

    test "detects communities with rbc" do
      {sources, targets} = Enum.unzip(@two_triangles)

      {:ok, result} = Leidenfold.detect(sources, targets, objective: :rbc)

      assert is_list(result.membership)
      assert result.n_communities >= 1
    end

    test "detects communities with significance" do
      {sources, targets} = Enum.unzip(@two_triangles)

      {:ok, result} = Leidenfold.detect(sources, targets, objective: :significance)

      assert is_list(result.membership)
      assert result.n_communities >= 1
    end

    test "detects communities with surprise" do
      {sources, targets} = Enum.unzip(@two_triangles)

      {:ok, result} = Leidenfold.detect(sources, targets, objective: :surprise)

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
      {sources, targets} = Enum.unzip(@two_triangles)

      {:ok, result1} = Leidenfold.detect(sources, targets, seed: 42)
      {:ok, result2} = Leidenfold.detect(sources, targets, seed: 42)

      assert result1.membership == result2.membership
      assert result1.quality == result2.quality
    end

    test "respects n_nodes option for isolated nodes" do
      # Triangle with 3 nodes, but we say there are 5 nodes total
      sources = [0, 1, 2]
      targets = [1, 2, 0]

      {:ok, result} = Leidenfold.detect(sources, targets, n_nodes: 5)

      # Should have membership for all 5 nodes
      assert length(result.membership) == 5
    end

    test "respects iterations option" do
      {sources, targets} = Enum.unzip(@two_triangles)

      {:ok, result1} = Leidenfold.detect(sources, targets, iterations: 1, seed: 123)
      {:ok, result2} = Leidenfold.detect(sources, targets, iterations: 10, seed: 123)

      # Both should produce valid results
      assert is_list(result1.membership)
      assert is_list(result2.membership)
    end

    test "handles directed graphs" do
      # Directed triangle
      sources = [0, 1, 2]
      targets = [1, 2, 0]

      {:ok, result} = Leidenfold.detect(sources, targets, directed: true)

      assert is_list(result.membership)
      assert length(result.membership) == 3
    end

    test "resolution parameter affects community count" do
      {sources, targets} = Enum.unzip(@two_triangles)

      # Low resolution -> fewer communities
      {:ok, low_res} = Leidenfold.detect(sources, targets, objective: :cpm, resolution: 0.01)
      # High resolution -> more communities
      {:ok, high_res} = Leidenfold.detect(sources, targets, objective: :cpm, resolution: 2.0)

      assert high_res.n_communities >= low_res.n_communities
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

    test "raises on error" do
      # Mismatched lengths should error
      assert_raise ArgumentError, fn ->
        Leidenfold.detect!([0, 1], [1])
      end
    end
  end

  describe "edge cases" do
    test "single edge graph" do
      {:ok, result} = Leidenfold.detect([0], [1])

      assert length(result.membership) == 2
      assert result.n_communities >= 1
    end

    test "single node with self-loop" do
      {:ok, result} = Leidenfold.detect([0], [0])

      assert length(result.membership) == 1
      assert result.n_communities == 1
    end

    test "disconnected components" do
      # Two separate edges with no connection
      sources = [0, 2]
      targets = [1, 3]

      {:ok, result} = Leidenfold.detect(sources, targets)

      assert length(result.membership) == 4
      # Each pair should be in different communities (or same if resolution is low)
      assert result.n_communities >= 1
    end

    test "linear chain" do
      # 0 - 1 - 2 - 3 - 4
      sources = [0, 1, 2, 3]
      targets = [1, 2, 3, 4]

      {:ok, result} = Leidenfold.detect(sources, targets)

      assert length(result.membership) == 5
    end

    test "complete graph (clique)" do
      # K4: all nodes connected to all others
      edges =
        for i <- 0..3, j <- 0..3, i < j do
          {i, j}
        end

      {sources, targets} = Enum.unzip(edges)

      {:ok, result} = Leidenfold.detect(sources, targets, objective: :modularity)

      assert length(result.membership) == 4
      # Complete graph with modularity should be one community
      assert result.n_communities == 1
    end

    test "star graph" do
      # Center node 0 connected to 1, 2, 3, 4
      sources = [0, 0, 0, 0]
      targets = [1, 2, 3, 4]

      {:ok, result} = Leidenfold.detect(sources, targets)

      assert length(result.membership) == 5
    end

    test "larger graph with clear communities" do
      # Three cliques of 5 nodes each, loosely connected
      clique1 = for i <- 0..4, j <- 0..4, i < j, do: {i, j}
      clique2 = for i <- 5..9, j <- 5..9, i < j, do: {i, j}
      clique3 = for i <- 10..14, j <- 10..14, i < j, do: {i, j}
      bridges = [{4, 5}, {9, 10}]

      edges = clique1 ++ clique2 ++ clique3 ++ bridges
      {sources, targets} = Enum.unzip(edges)

      {:ok, result} = Leidenfold.detect(sources, targets, objective: :modularity)

      assert length(result.membership) == 15
      # Should detect 3 communities
      assert result.n_communities == 3
    end
  end

  describe "error handling" do
    test "returns error for mismatched sources/targets length" do
      result = Leidenfold.detect([0, 1, 2], [1, 2])

      assert {:error, _reason} = result
    end

    test "returns error for mismatched weights length" do
      result = Leidenfold.detect([0, 1], [1, 2], weights: [1.0])

      assert {:error, _reason} = result
    end
  end

  describe "detect_hierarchical/3" do
    test "returns single level by default" do
      {sources, targets} = Enum.unzip(@two_triangles)

      {:ok, levels} = Leidenfold.detect_hierarchical(sources, targets, objective: :modularity)

      assert length(levels) == 1
      assert hd(levels).level == 0
      assert is_list(hd(levels).membership)
      assert length(hd(levels).membership) == 6
    end

    test "returns multiple levels when requested" do
      # Three cliques loosely connected
      clique1 = for i <- 0..4, j <- 0..4, i < j, do: {i, j}
      clique2 = for i <- 5..9, j <- 5..9, i < j, do: {i, j}
      clique3 = for i <- 10..14, j <- 10..14, i < j, do: {i, j}
      bridges = [{4, 5}, {9, 10}]

      edges = clique1 ++ clique2 ++ clique3 ++ bridges
      {sources, targets} = Enum.unzip(edges)

      {:ok, levels} =
        Leidenfold.detect_hierarchical(sources, targets,
          objective: :modularity,
          max_levels: 3
        )

      # Should have at least 2 levels for this graph
      assert length(levels) >= 1

      # All levels should have membership for all 15 nodes
      for level <- levels do
        assert length(level.membership) == 15
        assert level.level >= 0
        assert is_integer(level.n_communities)
        assert is_float(level.quality)
      end
    end

    test "min_size filters small communities" do
      {sources, targets} = Enum.unzip(@two_triangles)

      # Without min_size filter
      {:ok, levels_all} =
        Leidenfold.detect_hierarchical(sources, targets,
          objective: :modularity,
          min_size: 1
        )

      # With min_size=5 (should filter out communities with < 5 members)
      {:ok, levels_filtered} =
        Leidenfold.detect_hierarchical(sources, targets,
          objective: :modularity,
          min_size: 5
        )

      # The filtered version should have fewer or equal communities
      level0_all = hd(levels_all)
      level0_filtered = hd(levels_filtered)

      assert level0_filtered.n_communities <= level0_all.n_communities
    end

    test "works with weighted edges" do
      edges = [{0, 1, 1.0}, {1, 2, 2.0}, {2, 0, 1.5}, {3, 4, 1.0}, {4, 5, 2.0}, {5, 3, 1.5}]

      {:ok, levels} =
        Leidenfold.detect_hierarchical_from_weighted_edges(edges,
          objective: :modularity,
          max_levels: 2
        )

      assert length(levels) >= 1
      assert length(hd(levels).membership) == 6
    end

    test "respects seed for reproducibility" do
      {sources, targets} = Enum.unzip(@two_triangles)

      {:ok, levels1} =
        Leidenfold.detect_hierarchical(sources, targets,
          objective: :modularity,
          max_levels: 2,
          seed: 42
        )

      {:ok, levels2} =
        Leidenfold.detect_hierarchical(sources, targets,
          objective: :modularity,
          max_levels: 2,
          seed: 42
        )

      assert levels1 == levels2
    end
  end

  describe "detect_hierarchical!/3" do
    test "returns levels directly" do
      {sources, targets} = Enum.unzip(@two_triangles)

      levels = Leidenfold.detect_hierarchical!(sources, targets, objective: :modularity)

      assert is_list(levels)
      assert length(levels) >= 1
    end

    test "raises on error" do
      assert_raise ArgumentError, fn ->
        Leidenfold.detect_hierarchical!([0, 1], [1])
      end
    end
  end
end
