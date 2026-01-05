#ifndef LEIDEN_C_H
#define LEIDEN_C_H

#include <stddef.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef struct LeidenResult {
    size_t* membership;
    size_t n_nodes;
    size_t n_communities;
    double quality;
    int error_code;
    char* error_message;
} LeidenResult;

typedef struct LeidenLevelResult {
    size_t* membership;      // Community assignment for each original node
    size_t n_communities;    // Number of communities at this level
    double quality;          // Quality score at this level
} LeidenLevelResult;

typedef struct LeidenHierarchicalResult {
    LeidenLevelResult* levels;
    size_t n_levels;
    size_t n_nodes;          // Number of original nodes
    int error_code;
    char* error_message;
} LeidenHierarchicalResult;

typedef enum LeidenObjective {
    LEIDEN_CPM = 0,
    LEIDEN_MODULARITY = 1,
    LEIDEN_RBER = 2,
    LEIDEN_RBC = 3,
    LEIDEN_SIGNIFICANCE = 4,
    LEIDEN_SURPRISE = 5
} LeidenObjective;

typedef struct LeidenOptions {
    LeidenObjective objective;
    double resolution;
    size_t n_iterations;
    size_t seed;
    int consider_empty_community;
    size_t max_levels;    // For hierarchical: max levels (0 = single level)
    size_t min_size;      // For hierarchical: minimum community size
} LeidenOptions;

LeidenOptions leiden_default_options(void);

LeidenResult* leiden_find_communities(
    const int64_t* sources,
    const int64_t* targets,
    const double* weights,
    size_t n_edges,
    size_t n_nodes,
    int directed,
    const LeidenOptions* options
);

void leiden_free_result(LeidenResult* result);

LeidenHierarchicalResult* leiden_find_hierarchical_communities(
    const int64_t* sources,
    const int64_t* targets,
    const double* weights,
    size_t n_edges,
    size_t n_nodes,
    int directed,
    const LeidenOptions* options
);

void leiden_free_hierarchical_result(LeidenHierarchicalResult* result);

#ifdef __cplusplus
}
#endif

#endif // LEIDEN_C_H
