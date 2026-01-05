# Leidenfold

Elixir bindings for the Leiden community detection algorithm via [libleidenalg](https://github.com/vtraag/libleidenalg).

The Leiden algorithm is a state-of-the-art method for detecting communities in networks. It guarantees well-connected communities and runs significantly faster than the Louvain algorithm.

## Installation

Add `leidenfold` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:leidenfold, "~> 0.1.0"}
  ]
end
```

Precompiled binaries are available for:
- macOS (Apple Silicon)
- Linux (x86_64 and ARM64)

No additional setup is required for these platforms.

### Building from Source

If precompiled binaries are not available for your platform, or you want to build from source, set `LEIDENFOLD_BUILD=true` and install the prerequisites:

<details>
<summary>macOS</summary>

```bash
# Install igraph via Homebrew
brew install igraph

# Build and install libleidenalg
git clone https://github.com/vtraag/libleidenalg.git
cd libleidenalg
mkdir build && cd build
cmake .. -DCMAKE_INSTALL_PREFIX=$HOME/.local
make -j4
make install

# Build leidenfold from source
LEIDENFOLD_BUILD=true mix deps.compile leidenfold
```
</details>

<details>
<summary>Linux (Ubuntu/Debian)</summary>

```bash
# Install igraph
sudo apt-get install libigraph-dev

# Build and install libleidenalg
git clone https://github.com/vtraag/libleidenalg.git
cd libleidenalg
mkdir build && cd build
cmake .. -DCMAKE_INSTALL_PREFIX=$HOME/.local
make -j4
make install

# Build leidenfold from source
LEIDENFOLD_BUILD=true mix deps.compile leidenfold
```
</details>

<details>
<summary>Linux (Fedora/RHEL)</summary>

```bash
# Install igraph
sudo dnf install igraph-devel

# Build and install libleidenalg
git clone https://github.com/vtraag/libleidenalg.git
cd libleidenalg
mkdir build && cd build
cmake .. -DCMAKE_INSTALL_PREFIX=$HOME/.local
make -j4
make install

# Build leidenfold from source
LEIDENFOLD_BUILD=true mix deps.compile leidenfold
```
</details>

## Usage

```elixir
# Basic usage with edge tuples
edges = [{0, 1}, {1, 2}, {2, 0}, {3, 4}, {4, 5}, {5, 3}, {2, 3}]
{:ok, result} = Leidenfold.detect_from_edges(edges)
# => {:ok, %{membership: [0, 0, 0, 1, 1, 1], n_communities: 2, quality: 0.0}}

# Using source/target lists
sources = [0, 1, 2, 3, 4, 5, 2]
targets = [1, 2, 0, 4, 5, 3, 3]
{:ok, result} = Leidenfold.detect(sources, targets)

# With options
{:ok, result} = Leidenfold.detect(sources, targets,
  objective: :modularity,  # or :cpm, :rber, :rbc, :significance, :surprise
  resolution: 1.0,
  iterations: 2,
  seed: 42
)

# Weighted edges
weighted_edges = [{0, 1, 1.0}, {1, 2, 2.0}, {2, 0, 1.5}]
{:ok, result} = Leidenfold.detect_from_weighted_edges(weighted_edges)

# Bang version that raises on error
result = Leidenfold.detect!(sources, targets)
```

## Quality Functions

- `:cpm` - Constant Potts Model (default). Good for finding communities at different resolutions.
- `:modularity` - Classic modularity optimization.
- `:rber` - Reichardt-Bornholdt with Erdős-Rényi null model.
- `:rbc` - Reichardt-Bornholdt with configuration model null model.
- `:significance` - Significance-based community detection.
- `:surprise` - Surprise-based community detection.

## Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `:weights` | `[float]` | `nil` | Edge weights |
| `:n_nodes` | `integer` | auto | Number of nodes (inferred if not specified) |
| `:directed` | `boolean` | `false` | Whether graph is directed |
| `:objective` | `atom` | `:cpm` | Quality function to optimize |
| `:resolution` | `float` | `1.0` | Resolution parameter for CPM/RBER/RBC |
| `:iterations` | `integer` | `2` | Number of optimization iterations |
| `:seed` | `integer` | `0` | Random seed (0 = random) |

## Result

The `detect` functions return a map with:

- `:membership` - List of community assignments (0-indexed)
- `:n_communities` - Number of communities found
- `:quality` - Quality function value (modularity, CPM score, etc.)

## License

MIT
