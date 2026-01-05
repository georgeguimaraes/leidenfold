#include "leiden_c.h"

#include <igraph/igraph.h>
#include <libleidenalg/Optimiser.h>
#include <libleidenalg/GraphHelper.h>
#include <libleidenalg/CPMVertexPartition.h>
#include <libleidenalg/ModularityVertexPartition.h>
#include <libleidenalg/RBERVertexPartition.h>
#include <libleidenalg/RBConfigurationVertexPartition.h>
#include <libleidenalg/SignificanceVertexPartition.h>
#include <libleidenalg/SurpriseVertexPartition.h>

#include <cstring>
#include <vector>
#include <string>
#include <map>

extern "C" {

LeidenOptions leiden_default_options(void) {
    LeidenOptions opts;
    opts.objective = LEIDEN_CPM;
    opts.resolution = 1.0;
    opts.n_iterations = 2;
    opts.seed = 0;
    opts.consider_empty_community = 1;
    opts.max_levels = 1;
    opts.min_size = 1;
    return opts;
}

static LeidenHierarchicalResult* create_hierarchical_error_result(const char* message) {
    LeidenHierarchicalResult* result = new LeidenHierarchicalResult();
    result->levels = nullptr;
    result->n_levels = 0;
    result->n_nodes = 0;
    result->error_code = 1;
    result->error_message = strdup(message);
    return result;
}

static LeidenResult* create_error_result(const char* message) {
    LeidenResult* result = new LeidenResult();
    result->membership = nullptr;
    result->n_nodes = 0;
    result->n_communities = 0;
    result->quality = 0.0;
    result->error_code = 1;
    result->error_message = strdup(message);
    return result;
}

LeidenResult* leiden_find_communities(
    const int64_t* sources,
    const int64_t* targets,
    const double* weights,
    size_t n_edges,
    size_t n_nodes,
    int directed,
    const LeidenOptions* options
) {
    igraph_t graph;
    igraph_error_t err;

    // Create edge list
    igraph_vector_int_t edges;
    igraph_vector_int_init(&edges, n_edges * 2);
    for (size_t i = 0; i < n_edges; i++) {
        VECTOR(edges)[i * 2] = sources[i];
        VECTOR(edges)[i * 2 + 1] = targets[i];
    }

    // Create graph
    err = igraph_create(&graph, &edges, n_nodes, directed ? IGRAPH_DIRECTED : IGRAPH_UNDIRECTED);
    igraph_vector_int_destroy(&edges);

    if (err != IGRAPH_SUCCESS) {
        return create_error_result("Failed to create igraph");
    }

    // Create edge weights vector
    std::vector<double> edge_weights_vec;
    if (weights != nullptr) {
        edge_weights_vec.assign(weights, weights + n_edges);
    }

    // Create Graph wrapper
    Graph* leiden_graph;
    try {
        if (weights != nullptr) {
            leiden_graph = Graph::GraphFromEdgeWeights(&graph, edge_weights_vec);
        } else {
            leiden_graph = new Graph(&graph);
        }
    } catch (const std::exception& e) {
        igraph_destroy(&graph);
        return create_error_result(e.what());
    }

    // Create partition based on objective
    MutableVertexPartition* partition = nullptr;
    LeidenOptions opts = options ? *options : leiden_default_options();

    try {
        switch (opts.objective) {
            case LEIDEN_CPM:
                partition = new CPMVertexPartition(leiden_graph, opts.resolution);
                break;
            case LEIDEN_MODULARITY:
                partition = new ModularityVertexPartition(leiden_graph);
                break;
            case LEIDEN_RBER:
                partition = new RBERVertexPartition(leiden_graph, opts.resolution);
                break;
            case LEIDEN_RBC:
                partition = new RBConfigurationVertexPartition(leiden_graph, opts.resolution);
                break;
            case LEIDEN_SIGNIFICANCE:
                partition = new SignificanceVertexPartition(leiden_graph);
                break;
            case LEIDEN_SURPRISE:
                partition = new SurpriseVertexPartition(leiden_graph);
                break;
            default:
                partition = new CPMVertexPartition(leiden_graph, opts.resolution);
        }
    } catch (const std::exception& e) {
        delete leiden_graph;
        igraph_destroy(&graph);
        return create_error_result(e.what());
    }

    // Create optimiser and run
    Optimiser optimiser;
    if (opts.seed != 0) {
        optimiser.set_rng_seed(opts.seed);
    }
    optimiser.consider_empty_community = opts.consider_empty_community;

    try {
        for (size_t i = 0; i < opts.n_iterations; i++) {
            optimiser.optimise_partition(partition);
        }
    } catch (const std::exception& e) {
        delete partition;
        delete leiden_graph;
        igraph_destroy(&graph);
        return create_error_result(e.what());
    }

    // Get the actual quality score from the partition
    double quality = partition->quality();

    // Extract membership
    const std::vector<size_t>& membership = partition->membership();
    size_t n = membership.size();

    LeidenResult* result = new LeidenResult();
    result->membership = new size_t[n];
    std::memcpy(result->membership, membership.data(), n * sizeof(size_t));
    result->n_nodes = n;
    result->n_communities = partition->n_communities();
    result->quality = quality;
    result->error_code = 0;
    result->error_message = nullptr;

    // Cleanup
    delete partition;
    delete leiden_graph;
    igraph_destroy(&graph);

    return result;
}

void leiden_free_result(LeidenResult* result) {
    if (result) {
        if (result->membership) {
            delete[] result->membership;
        }
        if (result->error_message) {
            free(result->error_message);
        }
        delete result;
    }
}

// Helper: Run single-level Leiden and return partition
static MutableVertexPartition* run_leiden_on_graph(
    Graph* leiden_graph,
    const LeidenOptions& opts,
    Optimiser& optimiser
) {
    MutableVertexPartition* partition = nullptr;

    switch (opts.objective) {
        case LEIDEN_CPM:
            partition = new CPMVertexPartition(leiden_graph, opts.resolution);
            break;
        case LEIDEN_MODULARITY:
            partition = new ModularityVertexPartition(leiden_graph);
            break;
        case LEIDEN_RBER:
            partition = new RBERVertexPartition(leiden_graph, opts.resolution);
            break;
        case LEIDEN_RBC:
            partition = new RBConfigurationVertexPartition(leiden_graph, opts.resolution);
            break;
        case LEIDEN_SIGNIFICANCE:
            partition = new SignificanceVertexPartition(leiden_graph);
            break;
        case LEIDEN_SURPRISE:
            partition = new SurpriseVertexPartition(leiden_graph);
            break;
        default:
            partition = new CPMVertexPartition(leiden_graph, opts.resolution);
    }

    for (size_t i = 0; i < opts.n_iterations; i++) {
        optimiser.optimise_partition(partition);
    }

    return partition;
}

LeidenHierarchicalResult* leiden_find_hierarchical_communities(
    const int64_t* sources,
    const int64_t* targets,
    const double* weights,
    size_t n_edges,
    size_t n_nodes,
    int directed,
    const LeidenOptions* options
) {
    LeidenOptions opts = options ? *options : leiden_default_options();
    size_t max_levels = opts.max_levels > 0 ? opts.max_levels : 1;
    size_t min_size = opts.min_size > 0 ? opts.min_size : 1;

    // Prepare optimiser
    Optimiser optimiser;
    if (opts.seed != 0) {
        optimiser.set_rng_seed(opts.seed);
    }
    optimiser.consider_empty_community = opts.consider_empty_community;

    // Store results for each level
    std::vector<std::vector<size_t>> level_memberships;
    std::vector<size_t> level_n_communities;
    std::vector<double> level_qualities;

    // Current graph data (starts with original)
    std::vector<int64_t> cur_sources(sources, sources + n_edges);
    std::vector<int64_t> cur_targets(targets, targets + n_edges);
    std::vector<double> cur_weights;
    if (weights) {
        cur_weights.assign(weights, weights + n_edges);
    }
    size_t cur_n_nodes = n_nodes;

    // Track mapping from current nodes back to original nodes
    // Initially each node maps to itself
    std::vector<std::vector<size_t>> node_to_original(n_nodes);
    for (size_t i = 0; i < n_nodes; i++) {
        node_to_original[i].push_back(i);
    }

    for (size_t level = 0; level < max_levels; level++) {
        // Create igraph
        igraph_t graph;
        igraph_vector_int_t edges;
        igraph_vector_int_init(&edges, cur_sources.size() * 2);
        for (size_t i = 0; i < cur_sources.size(); i++) {
            VECTOR(edges)[i * 2] = cur_sources[i];
            VECTOR(edges)[i * 2 + 1] = cur_targets[i];
        }

        igraph_error_t err = igraph_create(&graph, &edges, cur_n_nodes,
            directed ? IGRAPH_DIRECTED : IGRAPH_UNDIRECTED);
        igraph_vector_int_destroy(&edges);

        if (err != IGRAPH_SUCCESS) {
            return create_hierarchical_error_result("Failed to create igraph");
        }

        // Create Graph wrapper
        Graph* leiden_graph;
        try {
            if (!cur_weights.empty()) {
                leiden_graph = Graph::GraphFromEdgeWeights(&graph, cur_weights);
            } else {
                leiden_graph = new Graph(&graph);
            }
        } catch (const std::exception& e) {
            igraph_destroy(&graph);
            return create_hierarchical_error_result(e.what());
        }

        // Run Leiden
        MutableVertexPartition* partition;
        try {
            partition = run_leiden_on_graph(leiden_graph, opts, optimiser);
        } catch (const std::exception& e) {
            delete leiden_graph;
            igraph_destroy(&graph);
            return create_hierarchical_error_result(e.what());
        }

        // Extract membership and map back to original nodes
        const std::vector<size_t>& membership = partition->membership();
        size_t n_communities = partition->n_communities();
        double quality = partition->quality();

        // Map current membership back to original nodes
        std::vector<size_t> original_membership(n_nodes, 0);
        for (size_t cur_node = 0; cur_node < cur_n_nodes; cur_node++) {
            size_t comm = membership[cur_node];
            for (size_t orig_node : node_to_original[cur_node]) {
                original_membership[orig_node] = comm;
            }
        }

        // Filter by min_size: count community sizes and mark small ones
        if (min_size > 1) {
            std::vector<size_t> comm_sizes(n_communities, 0);
            for (size_t m : original_membership) {
                comm_sizes[m]++;
            }
            // Remap communities, excluding small ones
            std::vector<size_t> comm_remap(n_communities, SIZE_MAX);
            size_t new_comm = 0;
            for (size_t c = 0; c < n_communities; c++) {
                if (comm_sizes[c] >= min_size) {
                    comm_remap[c] = new_comm++;
                }
            }
            // Apply remapping (nodes in small communities get SIZE_MAX, will be excluded)
            size_t filtered_n_communities = new_comm;
            for (size_t& m : original_membership) {
                m = comm_remap[m];
            }
            n_communities = filtered_n_communities;
        }

        level_memberships.push_back(original_membership);
        level_n_communities.push_back(n_communities);
        level_qualities.push_back(quality);

        // Check if we should stop
        if (level + 1 >= max_levels || n_communities <= 1) {
            delete partition;
            delete leiden_graph;
            igraph_destroy(&graph);
            break;
        }

        // Build aggregated graph for next level
        // Communities become nodes, edges weighted by inter-community connections
        size_t agg_n_nodes = partition->n_communities();
        std::map<std::pair<size_t, size_t>, double> agg_edge_weights;

        for (size_t e = 0; e < cur_sources.size(); e++) {
            size_t src_comm = membership[cur_sources[e]];
            size_t tgt_comm = membership[cur_targets[e]];
            if (src_comm != tgt_comm) {
                // Normalize edge direction for consistency
                auto key = src_comm < tgt_comm
                    ? std::make_pair(src_comm, tgt_comm)
                    : std::make_pair(tgt_comm, src_comm);
                double w = cur_weights.empty() ? 1.0 : cur_weights[e];
                agg_edge_weights[key] += w;
            }
        }

        // Build new node_to_original mapping
        std::vector<std::vector<size_t>> new_node_to_original(agg_n_nodes);
        for (size_t cur_node = 0; cur_node < cur_n_nodes; cur_node++) {
            size_t comm = membership[cur_node];
            for (size_t orig_node : node_to_original[cur_node]) {
                new_node_to_original[comm].push_back(orig_node);
            }
        }
        node_to_original = std::move(new_node_to_original);

        // Convert aggregated edges to vectors
        cur_sources.clear();
        cur_targets.clear();
        cur_weights.clear();
        for (const auto& [key, weight] : agg_edge_weights) {
            cur_sources.push_back(key.first);
            cur_targets.push_back(key.second);
            cur_weights.push_back(weight);
        }
        cur_n_nodes = agg_n_nodes;

        delete partition;
        delete leiden_graph;
        igraph_destroy(&graph);

        // Stop if no edges remain
        if (cur_sources.empty()) {
            break;
        }
    }

    // Build result
    LeidenHierarchicalResult* result = new LeidenHierarchicalResult();
    result->n_levels = level_memberships.size();
    result->n_nodes = n_nodes;
    result->levels = new LeidenLevelResult[result->n_levels];
    result->error_code = 0;
    result->error_message = nullptr;

    for (size_t l = 0; l < result->n_levels; l++) {
        result->levels[l].membership = new size_t[n_nodes];
        std::memcpy(result->levels[l].membership, level_memberships[l].data(), n_nodes * sizeof(size_t));
        result->levels[l].n_communities = level_n_communities[l];
        result->levels[l].quality = level_qualities[l];
    }

    return result;
}

void leiden_free_hierarchical_result(LeidenHierarchicalResult* result) {
    if (result) {
        if (result->levels) {
            for (size_t i = 0; i < result->n_levels; i++) {
                if (result->levels[i].membership) {
                    delete[] result->levels[i].membership;
                }
            }
            delete[] result->levels;
        }
        if (result->error_message) {
            free(result->error_message);
        }
        delete result;
    }
}

} // extern "C"
