using Pkg

# Set Julia environment path
juliaenv = "."

# Activate environment
Pkg.activate(juliaenv)

# Set Julia development dir
ENV["JULIA_PKG_DEVDIR"] = abspath(joinpath(juliaenv, "dev"))

# Develop ProgressiveHedging so I can debug it
Pkg.add("https://github.com/NREL/ProgressiveHedging.jl.git", rev="integers")
Pkg.develop("ProgressiveHedging")