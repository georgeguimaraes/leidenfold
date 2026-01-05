defmodule Leidenfold do
  @moduledoc """
  Elixir bindings for the Leiden community detection algorithm.

  Leidenfold wraps libleidenalg, the reference C++ implementation of the
  Leiden algorithm by Vincent Traag.

  ## Example

      # Create edge list (source, target pairs)
      edges = [{0, 1}, {1, 2}, {2, 0}, {3, 4}, {4, 5}, {5, 3}]
      sources = Enum.map(edges, &elem(&1, 0))
      targets = Enum.map(edges, &elem(&1, 1))

      # Detect communities
      {:ok, result} = Leidenfold.detect(sources, targets, n_nodes: 6)
      # => {:ok, %{membership: [0, 0, 0, 1, 1, 1], n_communities: 2, quality: 0.5}}

  ## Quality Functions

  - `:cpm` - Constant Potts Model (default). Good for finding communities at different resolutions.
  - `:modularity` - Classic modularity optimization.
  - `:rber` - Reichardt-Bornholdt with Erdős-Rényi null model.
  - `:rbc` - Reichardt-Bornholdt with configuration model null model.
  - `:significance` - Significance-based community detection.
  - `:surprise` - Surprise-based community detection.
  """

  @type objective ::
          :cpm | :modularity | :rber | :rbc | :significance | :surprise

  @type result :: %{
          membership: [non_neg_integer()],
          n_communities: non_neg_integer(),
          quality: float()
        }

  @type option ::
          {:weights, [float()] | nil}
          | {:n_nodes, non_neg_integer() | nil}
          | {:directed, boolean()}
          | {:objective, objective()}
          | {:resolution, float()}
          | {:iterations, pos_integer()}
          | {:seed, non_neg_integer()}

  @doc """
  Detect communities in a graph using the Leiden algorithm.

  ## Parameters

  - `sources` - List of source node IDs for each edge
  - `targets` - List of target node IDs for each edge

  ## Options

  - `:weights` - Edge weights (default: nil for unweighted)
  - `:n_nodes` - Number of nodes (default: inferred from max node ID + 1)
  - `:directed` - Whether graph is directed (default: false)
  - `:objective` - Quality function (default: :cpm)
  - `:resolution` - Resolution parameter (default: 1.0)
  - `:iterations` - Number of optimization iterations (default: 2)
  - `:seed` - Random seed, 0 for random (default: 0)

  ## Returns

  - `{:ok, result}` where result is a map with `:membership`, `:n_communities`, and `:quality`
  - `{:error, reason}` on failure
  """
  @spec detect([integer()], [integer()], [option()]) :: {:ok, result()} | {:error, String.t()}
  def detect(sources, targets, opts \\ []) when is_list(sources) and is_list(targets) do
    weights = Keyword.get(opts, :weights)
    directed = Keyword.get(opts, :directed, false)
    objective = Keyword.get(opts, :objective, :cpm)
    resolution = Keyword.get(opts, :resolution, 1.0)
    iterations = Keyword.get(opts, :iterations, 2)
    seed = Keyword.get(opts, :seed, 0)

    n_nodes =
      Keyword.get_lazy(opts, :n_nodes, fn ->
        max_node =
          [sources, targets]
          |> List.flatten()
          |> Enum.max(fn -> -1 end)

        max_node + 1
      end)

    case Leidenfold.Native.detect_communities(
           sources,
           targets,
           weights,
           n_nodes,
           directed,
           objective,
           resolution,
           iterations,
           seed
         ) do
      {:ok, {membership, n_communities, quality}} ->
        {:ok,
         %{
           membership: membership,
           n_communities: n_communities,
           quality: quality
         }}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Same as `detect/3` but raises on error.
  """
  @spec detect!([integer()], [integer()], [option()]) :: result()
  def detect!(sources, targets, opts \\ []) do
    case detect(sources, targets, opts) do
      {:ok, result} -> result
      {:error, reason} -> raise ArgumentError, reason
    end
  end

  @doc """
  Detect communities from a list of edge tuples.

  ## Example

      edges = [{0, 1}, {1, 2}, {2, 0}]
      {:ok, result} = Leidenfold.detect_from_edges(edges)
  """
  @spec detect_from_edges([{integer(), integer()}], [option()]) ::
          {:ok, result()} | {:error, String.t()}
  def detect_from_edges(edges, opts \\ []) when is_list(edges) do
    {sources, targets} = Enum.unzip(edges)
    detect(sources, targets, opts)
  end

  @doc """
  Detect communities from a list of weighted edge tuples.

  ## Example

      edges = [{0, 1, 1.0}, {1, 2, 2.0}, {2, 0, 1.5}]
      {:ok, result} = Leidenfold.detect_from_weighted_edges(edges)
  """
  @spec detect_from_weighted_edges([{integer(), integer(), float()}], [option()]) ::
          {:ok, result()} | {:error, String.t()}
  def detect_from_weighted_edges(edges, opts \\ []) when is_list(edges) do
    {sources, targets, weights} =
      edges
      |> Enum.reduce({[], [], []}, fn {s, t, w}, {ss, ts, ws} ->
        {[s | ss], [t | ts], [w | ws]}
      end)
      |> then(fn {ss, ts, ws} ->
        {Enum.reverse(ss), Enum.reverse(ts), Enum.reverse(ws)}
      end)

    detect(sources, targets, Keyword.put(opts, :weights, weights))
  end

  @type hierarchical_option ::
          option()
          | {:max_levels, pos_integer()}
          | {:min_size, pos_integer()}

  @type level_result :: %{
          level: non_neg_integer(),
          membership: [non_neg_integer()],
          n_communities: non_neg_integer(),
          quality: float()
        }

  @doc """
  Detect hierarchical communities in a graph using the Leiden algorithm.

  This runs the Leiden algorithm iteratively, aggregating communities at each level
  to form higher-level groupings. Level 0 contains the finest communities, and each
  subsequent level groups communities from the previous level.

  ## Parameters

  - `sources` - List of source node IDs for each edge
  - `targets` - List of target node IDs for each edge

  ## Options

  All options from `detect/3`, plus:

  - `:max_levels` - Maximum hierarchy levels to generate (default: 1)
  - `:min_size` - Minimum community size (default: 1, set higher to exclude small communities)

  ## Returns

  - `{:ok, levels}` where levels is a list of maps with `:level`, `:membership`, `:n_communities`, and `:quality`
  - `{:error, reason}` on failure

  ## Example

      edges = [{0, 1}, {1, 2}, {2, 0}, {3, 4}, {4, 5}, {5, 3}, {2, 3}]
      sources = Enum.map(edges, &elem(&1, 0))
      targets = Enum.map(edges, &elem(&1, 1))

      {:ok, levels} = Leidenfold.detect_hierarchical(sources, targets, max_levels: 3)
      # => {:ok, [
      #      %{level: 0, membership: [0, 0, 0, 1, 1, 1], n_communities: 2, quality: 0.5},
      #      %{level: 1, membership: [0, 0, 0, 0, 0, 0], n_communities: 1, quality: 0.0}
      #    ]}
  """
  @spec detect_hierarchical([integer()], [integer()], [hierarchical_option()]) ::
          {:ok, [level_result()]} | {:error, String.t()}
  def detect_hierarchical(sources, targets, opts \\ [])
      when is_list(sources) and is_list(targets) do
    weights = Keyword.get(opts, :weights)
    directed = Keyword.get(opts, :directed, false)
    objective = Keyword.get(opts, :objective, :cpm)
    resolution = Keyword.get(opts, :resolution, 1.0)
    iterations = Keyword.get(opts, :iterations, 2)
    seed = Keyword.get(opts, :seed, 0)
    max_levels = Keyword.get(opts, :max_levels, 1)
    min_size = Keyword.get(opts, :min_size, 1)

    n_nodes =
      Keyword.get_lazy(opts, :n_nodes, fn ->
        max_node =
          [sources, targets]
          |> List.flatten()
          |> Enum.max(fn -> -1 end)

        max_node + 1
      end)

    case Leidenfold.Native.detect_hierarchical_communities(
           sources,
           targets,
           weights,
           n_nodes,
           directed,
           objective,
           resolution,
           iterations,
           seed,
           max_levels,
           min_size
         ) do
      {:ok, levels} ->
        formatted =
          levels
          |> Enum.with_index()
          |> Enum.map(fn {{membership, n_communities, quality}, level} ->
            %{
              level: level,
              membership: membership,
              n_communities: n_communities,
              quality: quality
            }
          end)

        {:ok, formatted}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Same as `detect_hierarchical/3` but raises on error.
  """
  @spec detect_hierarchical!([integer()], [integer()], [hierarchical_option()]) :: [level_result()]
  def detect_hierarchical!(sources, targets, opts \\ []) do
    case detect_hierarchical(sources, targets, opts) do
      {:ok, result} -> result
      {:error, reason} -> raise ArgumentError, reason
    end
  end

  @doc """
  Detect hierarchical communities from a list of weighted edge tuples.

  ## Example

      edges = [{0, 1, 1.0}, {1, 2, 2.0}, {2, 0, 1.5}]
      {:ok, levels} = Leidenfold.detect_hierarchical_from_weighted_edges(edges, max_levels: 3)
  """
  @spec detect_hierarchical_from_weighted_edges(
          [{integer(), integer(), float()}],
          [hierarchical_option()]
        ) ::
          {:ok, [level_result()]} | {:error, String.t()}
  def detect_hierarchical_from_weighted_edges(edges, opts \\ []) when is_list(edges) do
    {sources, targets, weights} =
      edges
      |> Enum.reduce({[], [], []}, fn {s, t, w}, {ss, ts, ws} ->
        {[s | ss], [t | ts], [w | ws]}
      end)
      |> then(fn {ss, ts, ws} ->
        {Enum.reverse(ss), Enum.reverse(ts), Enum.reverse(ws)}
      end)

    detect_hierarchical(sources, targets, Keyword.put(opts, :weights, weights))
  end
end
