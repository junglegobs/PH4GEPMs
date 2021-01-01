using Pkg

# Set Julia environment path
juliaenv = "."

# Activate environment
Pkg.activate(juliaenv)

# Set Julia development dir
ENV["JULIA_PKG_DEVDIR"] = abspath(joinpath(juliaenv, "pkgs"))

# Add packages from Project.toml
Pkg.instantiate()

