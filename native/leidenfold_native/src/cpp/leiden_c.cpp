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

extern "C" {

LeidenOptions leiden_default_options(void) {
    LeidenOptions opts;
    opts.objective = LEIDEN_CPM;
    opts.resolution = 1.0;
    opts.n_iterations = 2;
    opts.seed = 0;
    opts.consider_empty_community = 1;
    return opts;
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

} // extern "C"
