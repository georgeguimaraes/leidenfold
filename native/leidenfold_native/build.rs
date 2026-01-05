use std::env;
use std::path::PathBuf;

fn main() {
    let home = env::var("HOME").expect("HOME not set");
    let static_link = env::var("STATIC_LINK").is_ok();

    // Check for CI-provided paths first, then fall back to ~/.local
    let static_lib_path = env::var("LEIDENFOLD_STATIC_LIB_PATH")
        .unwrap_or_else(|_| format!("{home}/.local/lib"));
    let static_include_path = env::var("LEIDENFOLD_STATIC_INCLUDE_PATH")
        .unwrap_or_else(|_| format!("{home}/.local/include"));

    // Find igraph via pkg-config or homebrew (for dynamic linking)
    let igraph = if !static_link {
        pkg_config::Config::new().probe("igraph").ok()
    } else {
        None
    };

    let (igraph_include, igraph_lib) = if let Some(ref lib) = igraph {
        // pkg-config may return paths like .../include/igraph, but we need .../include
        // for #include <igraph/igraph.h> to work
        let includes: Vec<PathBuf> = lib
            .include_paths
            .iter()
            .map(|p| {
                if p.ends_with("igraph") {
                    p.parent().unwrap_or(p).to_path_buf()
                } else {
                    p.clone()
                }
            })
            .collect();
        (includes, lib.link_paths.clone())
    } else if static_link {
        // Static linking: use provided paths
        (
            vec![PathBuf::from(&static_include_path)],
            vec![PathBuf::from(&static_lib_path)],
        )
    } else {
        // Fallback to homebrew locations
        let homebrew_prefix = if cfg!(target_arch = "aarch64") {
            "/opt/homebrew"
        } else {
            "/usr/local"
        };
        (
            vec![PathBuf::from(format!("{homebrew_prefix}/include"))],
            vec![PathBuf::from(format!("{homebrew_prefix}/lib"))],
        )
    };

    // Build the C++ wrapper
    let mut build = cc::Build::new();
    build
        .cpp(true)
        .file("src/cpp/leiden_c.cpp")
        .include(&static_include_path)
        .std("c++17");

    for path in &igraph_include {
        build.include(path);
    }

    // macOS specific flags
    if cfg!(target_os = "macos") {
        build.flag("-stdlib=libc++");
    }

    build.compile("leiden_c");

    // Link libraries
    println!("cargo:rustc-link-search=native={static_lib_path}");
    for path in &igraph_lib {
        println!("cargo:rustc-link-search=native={}", path.display());
    }

    if static_link {
        // Static linking for precompiled releases
        println!("cargo:rustc-link-lib=static=libleidenalg");
        println!("cargo:rustc-link-lib=static=igraph");

        if cfg!(target_os = "macos") {
            println!("cargo:rustc-link-lib=dylib=c++");
        } else {
            println!("cargo:rustc-link-lib=dylib=stdc++");
            println!("cargo:rustc-link-lib=dylib=m");
        }
    } else {
        // Dynamic linking for local development
        println!("cargo:rustc-link-lib=dylib=libleidenalg");
        println!("cargo:rustc-link-lib=dylib=igraph");

        if cfg!(target_os = "macos") {
            println!("cargo:rustc-link-lib=dylib=c++");
            // Add rpath so dylibs can be found at runtime
            println!("cargo:rustc-link-arg=-Wl,-rpath,{static_lib_path}");
            for path in &igraph_lib {
                println!("cargo:rustc-link-arg=-Wl,-rpath,{}", path.display());
            }
        } else {
            println!("cargo:rustc-link-lib=dylib=stdc++");
            // Add rpath for Linux
            println!("cargo:rustc-link-arg=-Wl,-rpath,{static_lib_path}");
            for path in &igraph_lib {
                println!("cargo:rustc-link-arg=-Wl,-rpath,{}", path.display());
            }
        }
    }

    // Rerun if source changes
    println!("cargo:rerun-if-changed=src/cpp/leiden_c.cpp");
    println!("cargo:rerun-if-changed=src/cpp/leiden_c.h");
    println!("cargo:rerun-if-env-changed=STATIC_LINK");
    println!("cargo:rerun-if-env-changed=LEIDENFOLD_STATIC_LIB_PATH");
    println!("cargo:rerun-if-env-changed=LEIDENFOLD_STATIC_INCLUDE_PATH");
}
