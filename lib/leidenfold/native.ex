defmodule Leidenfold.Native do
  @moduledoc false

  version = Mix.Project.config()[:version]

  use RustlerPrecompiled,
    otp_app: :leidenfold,
    crate: "leidenfold_native",
    base_url: "https://github.com/georgeguimaraes/leidenfold/releases/download/v#{version}",
    force_build: System.get_env("LEIDENFOLD_BUILD") in ["1", "true"],
    version: version,
    targets: [
      "aarch64-apple-darwin",
      "x86_64-unknown-linux-gnu",
      "aarch64-unknown-linux-gnu"
    ]

  @doc """
  Detect communities using the Leiden algorithm.

  ## Parameters
    - sources: list of source node IDs (integers)
    - targets: list of target node IDs (integers)
    - weights: optional list of edge weights (floats), or nil for unweighted
    - n_nodes: total number of nodes in the graph
    - directed: whether the graph is directed
    - objective: quality function (:cpm, :modularity, :rber, :rbc, :significance, :surprise)
    - resolution: resolution parameter (typically 1.0)
    - n_iterations: number of optimization iterations (typically 2)
    - seed: random seed (0 for random)

  ## Returns
    - `{:ok, {membership, n_communities, quality}}` on success
    - `{:error, reason}` on failure
  """
  def detect_communities(
        _sources,
        _targets,
        _weights,
        _n_nodes,
        _directed,
        _objective,
        _resolution,
        _n_iterations,
        _seed
      ),
      do: :erlang.nif_error(:nif_not_loaded)
end
