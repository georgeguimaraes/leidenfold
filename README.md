# Leidenfold

Elixir bindings for the Leiden community detection algorithm via [libleidenalg](https://github.com/vtraag/libleidenalg).

The Leiden algorithm is a state-of-the-art method for detecting communities in networks. It guarantees well-connected communities and runs significantly faster than the Louvain algorithm.

## Installation

Add `leidenfold` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:leidenfold, "~> 0.2.0"}
  ]
end
```

Precompiled binaries are available for:
- macOS (Apple Silicon)
- Linux (x86_64, ARM64)

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
# Two triangles connected by edge 2-3:
#     0               3
#    / \             / \
#   1---2 --------- 4---5
edges = [{0, 1}, {1, 2}, {2, 0}, {3, 4}, {4, 5}, {5, 3}, {2, 3}]
{:ok, result} = Leidenfold.detect_from_edges(edges)
# => {:ok, %{membership: [0, 0, 0, 1, 1, 1], n_communities: 2, quality: 0.0}}
# Nodes 0,1,2 form community 0; nodes 3,4,5 form community 1

# Same graph using source/target lists (pairs source[i] -> target[i])
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
- `:rber` - Reichardt-Bornholdt with Erdos-Renyi null model.
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

## Contributing

### Dependencies

Leidenfold builds against these native libraries (statically linked in precompiled binaries):

- [igraph](https://github.com/igraph/igraph) 0.10.15
- [libleidenalg](https://github.com/vtraag/libleidenalg) 0.11.1

### Development Setup

To build and test locally:

```bash
# Install build dependencies (macOS)
brew install cmake automake autoconf libtool bison flex
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

# Clone the repo
git clone https://github.com/georgeguimaraes/leidenfold.git
cd leidenfold

# Build igraph from source (static)
git clone --depth 1 --branch 0.10.15 https://github.com/igraph/igraph.git
cd igraph && mkdir build && cd build
cmake .. \
  -DCMAKE_INSTALL_PREFIX="$HOME/.local" \
  -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
  -DBUILD_SHARED_LIBS=OFF \
  -DIGRAPH_USE_INTERNAL_BLAS=ON \
  -DIGRAPH_USE_INTERNAL_LAPACK=ON \
  -DIGRAPH_USE_INTERNAL_ARPACK=ON \
  -DIGRAPH_USE_INTERNAL_GLPK=ON \
  -DIGRAPH_USE_INTERNAL_GMP=ON
make -j$(sysctl -n hw.ncpu)
make install
cd ../..

# Build libleidenalg from source (static)
git clone --depth 1 --branch 0.11.1 https://github.com/vtraag/libleidenalg.git
cd libleidenalg && mkdir build && cd build
cmake .. \
  -DCMAKE_INSTALL_PREFIX="$HOME/.local" \
  -DCMAKE_PREFIX_PATH="$HOME/.local" \
  -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
  -DBUILD_SHARED_LIBS=OFF
make -j$(sysctl -n hw.ncpu)
make install
cd ../..

# Build and test
mix deps.get
LEIDENFOLD_BUILD=true \
  LEIDENFOLD_STATIC_LIB_PATH="$HOME/.local/lib" \
  LEIDENFOLD_STATIC_INCLUDE_PATH="$HOME/.local/include" \
  mix test
```

### CI Pipeline

The CI pipeline runs on GitHub Actions:

1. **Test job** - Runs on Linux with OTP 26/27/28 and Elixir 1.17/1.18/1.19 (8 combinations)
2. **Build and Publish** - Triggered on version tags (`v*`), builds precompiled NIFs:
   - macOS ARM64 (Apple Silicon)
   - Linux x86_64
   - Linux ARM64
3. **Release** - Uploads artifacts to GitHub Releases
4. **Checksums** - Auto-generates and commits checksum file
5. **Hex Publish** - Publishes to hex.pm

NIFs are built for NIF versions 2.15, 2.16, and 2.17 to support OTP 22+.

## License

MIT
