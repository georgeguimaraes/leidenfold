use std::env;
use std::path::PathBuf;

fn main() {
    let home = env::var("HOME").expect("HOME not set");
    let local_lib = format!("{home}/.local/lib");
    let local_include = format!("{home}/.local/include");

    // Find igraph via pkg-config or homebrew
    let igraph = pkg_config::Config::new().probe("igraph").ok();

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
        .include(&local_include)
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
    println!("cargo:rustc-link-search=native={local_lib}");
    for path in &igraph_lib {
        println!("cargo:rustc-link-search=native={}", path.display());
    }

    println!("cargo:rustc-link-lib=dylib=libleidenalg");
    println!("cargo:rustc-link-lib=dylib=igraph");

    if cfg!(target_os = "macos") {
        println!("cargo:rustc-link-lib=dylib=c++");
        // Add rpath so dylibs can be found at runtime
        println!("cargo:rustc-link-arg=-Wl,-rpath,{local_lib}");
        for path in &igraph_lib {
            println!("cargo:rustc-link-arg=-Wl,-rpath,{}", path.display());
        }
    } else {
        println!("cargo:rustc-link-lib=dylib=stdc++");
        // Add rpath for Linux
        println!("cargo:rustc-link-arg=-Wl,-rpath,{local_lib}");
        for path in &igraph_lib {
            println!("cargo:rustc-link-arg=-Wl,-rpath,{}", path.display());
        }
    }

    // Rerun if source changes
    println!("cargo:rerun-if-changed=src/cpp/leiden_c.cpp");
    println!("cargo:rerun-if-changed=src/cpp/leiden_c.h");
}
