use rustler::Atom;
use std::ffi::CStr;

mod atoms {
    rustler::atoms! {
        ok,
        error,
        cpm,
        modularity,
        rber,
        rbc,
        significance,
        surprise,
    }
}

#[repr(C)]
struct LeidenResult {
    membership: *mut usize,
    n_nodes: usize,
    n_communities: usize,
    quality: f64,
    error_code: i32,
    error_message: *mut std::os::raw::c_char,
}

#[repr(C)]
struct LeidenLevelResult {
    membership: *mut usize,
    n_communities: usize,
    quality: f64,
}

#[repr(C)]
struct LeidenHierarchicalResult {
    levels: *mut LeidenLevelResult,
    n_levels: usize,
    n_nodes: usize,
    error_code: i32,
    error_message: *mut std::os::raw::c_char,
}

#[repr(C)]
#[derive(Clone, Copy)]
enum LeidenObjective {
    Cpm = 0,
    Modularity = 1,
    Rber = 2,
    Rbc = 3,
    Significance = 4,
    Surprise = 5,
}

#[repr(C)]
struct LeidenOptions {
    objective: LeidenObjective,
    resolution: f64,
    n_iterations: usize,
    seed: usize,
    consider_empty_community: i32,
    max_levels: usize,
    min_size: usize,
}

extern "C" {
    fn leiden_find_communities(
        sources: *const i64,
        targets: *const i64,
        weights: *const f64,
        n_edges: usize,
        n_nodes: usize,
        directed: i32,
        options: *const LeidenOptions,
    ) -> *mut LeidenResult;

    fn leiden_free_result(result: *mut LeidenResult);

    fn leiden_find_hierarchical_communities(
        sources: *const i64,
        targets: *const i64,
        weights: *const f64,
        n_edges: usize,
        n_nodes: usize,
        directed: i32,
        options: *const LeidenOptions,
    ) -> *mut LeidenHierarchicalResult;

    fn leiden_free_hierarchical_result(result: *mut LeidenHierarchicalResult);
}

fn objective_from_atom(atom: Atom) -> LeidenObjective {
    if atom == atoms::modularity() {
        LeidenObjective::Modularity
    } else if atom == atoms::rber() {
        LeidenObjective::Rber
    } else if atom == atoms::rbc() {
        LeidenObjective::Rbc
    } else if atom == atoms::significance() {
        LeidenObjective::Significance
    } else if atom == atoms::surprise() {
        LeidenObjective::Surprise
    } else {
        LeidenObjective::Cpm
    }
}

/// Detect communities using the Leiden algorithm.
///
/// Returns `{:ok, {membership, n_communities, quality}}` or `{:error, reason}`.
#[rustler::nif(schedule = "DirtyCpu")]
fn detect_communities(
    sources: Vec<i64>,
    targets: Vec<i64>,
    weights: Option<Vec<f64>>,
    n_nodes: usize,
    directed: bool,
    objective: Atom,
    resolution: f64,
    n_iterations: usize,
    seed: usize,
) -> Result<(Vec<usize>, usize, f64), String> {
    if sources.len() != targets.len() {
        return Err("sources and targets must have same length".to_string());
    }

    if let Some(ref w) = weights {
        if w.len() != sources.len() {
            return Err("weights must have same length as edges".to_string());
        }
    }

    let n_edges = sources.len();
    let weights_ptr = weights
        .as_ref()
        .map(|w| w.as_ptr())
        .unwrap_or(std::ptr::null());

    let options = LeidenOptions {
        objective: objective_from_atom(objective),
        resolution,
        n_iterations,
        seed,
        consider_empty_community: 1,
        max_levels: 1,
        min_size: 1,
    };

    let result = unsafe {
        leiden_find_communities(
            sources.as_ptr(),
            targets.as_ptr(),
            weights_ptr,
            n_edges,
            n_nodes,
            if directed { 1 } else { 0 },
            &options,
        )
    };

    if result.is_null() {
        return Err("Failed to allocate result".to_string());
    }

    let res = unsafe { &*result };

    if res.error_code != 0 {
        let error_msg = if res.error_message.is_null() {
            "Unknown error".to_string()
        } else {
            unsafe {
                CStr::from_ptr(res.error_message)
                    .to_string_lossy()
                    .to_string()
            }
        };
        unsafe { leiden_free_result(result) };
        return Err(error_msg);
    }

    let membership: Vec<usize> =
        unsafe { std::slice::from_raw_parts(res.membership, res.n_nodes).to_vec() };
    let n_communities = res.n_communities;
    let quality = res.quality;

    unsafe { leiden_free_result(result) };

    Ok((membership, n_communities, quality))
}

/// Detect hierarchical communities using the Leiden algorithm.
///
/// Returns `{:ok, levels}` where levels is a list of `{membership, n_communities, quality}` tuples,
/// or `{:error, reason}`.
#[rustler::nif(schedule = "DirtyCpu")]
fn detect_hierarchical_communities(
    sources: Vec<i64>,
    targets: Vec<i64>,
    weights: Option<Vec<f64>>,
    n_nodes: usize,
    directed: bool,
    objective: Atom,
    resolution: f64,
    n_iterations: usize,
    seed: usize,
    max_levels: usize,
    min_size: usize,
) -> Result<Vec<(Vec<usize>, usize, f64)>, String> {
    if sources.len() != targets.len() {
        return Err("sources and targets must have same length".to_string());
    }

    if let Some(ref w) = weights {
        if w.len() != sources.len() {
            return Err("weights must have same length as edges".to_string());
        }
    }

    let n_edges = sources.len();
    let weights_ptr = weights
        .as_ref()
        .map(|w| w.as_ptr())
        .unwrap_or(std::ptr::null());

    let options = LeidenOptions {
        objective: objective_from_atom(objective),
        resolution,
        n_iterations,
        seed,
        consider_empty_community: 1,
        max_levels,
        min_size,
    };

    let result = unsafe {
        leiden_find_hierarchical_communities(
            sources.as_ptr(),
            targets.as_ptr(),
            weights_ptr,
            n_edges,
            n_nodes,
            if directed { 1 } else { 0 },
            &options,
        )
    };

    if result.is_null() {
        return Err("Failed to allocate result".to_string());
    }

    let res = unsafe { &*result };

    if res.error_code != 0 {
        let error_msg = if res.error_message.is_null() {
            "Unknown error".to_string()
        } else {
            unsafe {
                CStr::from_ptr(res.error_message)
                    .to_string_lossy()
                    .to_string()
            }
        };
        unsafe { leiden_free_hierarchical_result(result) };
        return Err(error_msg);
    }

    // Extract all levels
    let mut levels = Vec::with_capacity(res.n_levels);
    for i in 0..res.n_levels {
        let level = unsafe { &*res.levels.add(i) };
        let membership: Vec<usize> =
            unsafe { std::slice::from_raw_parts(level.membership, res.n_nodes).to_vec() };
        levels.push((membership, level.n_communities, level.quality));
    }

    unsafe { leiden_free_hierarchical_result(result) };

    Ok(levels)
}

rustler::init!("Elixir.Leidenfold.Native");
