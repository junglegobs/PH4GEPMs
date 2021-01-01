using Pkg

# Activate environment at current directory
Pkg.activate(dirname(@__FILE__))

# Download and install all required packages
Pkg.instantiate()

# Precompile everyting
Pkg.API.precompile()

# Load packages
using Revise
using JuMP

# Include other scripts
for (root, subdirs, files) in walkdir(abspath(@__DIR__, "functions"))
    for f in (f for f in files if f != "GEPPR.jl" && match(r"^\w+\.jl",f) != nothing)
        includet(joinpath(root,f))
    end
end

# Constant values which may be useful
const ROOT_DIR = @__DIR__

# Other stuff
ENV["JULIA_DEBUG"] = "all" # Shows debug messages in all packages
