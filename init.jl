using Pkg

# Activate environment at current directory
Pkg.activate(dirname(@__FILE__))

# Download and install all required packages
Pkg.instantiate()

# Precompile everyting
Pkg.API.precompile()

# Constants
using Gurobi
const GRB_ENV = Gurobi.Env() # This needs to be 

# Include other scripts
using Revise # So I can do includet
for (root, subdirs, files) in walkdir(abspath(@__DIR__, "functions"))
    for f in (f for f in files if match(r"^\w+\.jl",f) !== nothing)
        includet(joinpath(root,f))
    end
end

# Other stuff
ENV["JULIA_DEBUG"] = "Main" # Show debug messages for packages

# Get compilation times out of the way
using COSMO # she's a particularly bad culprit of this
solve_dummy_problem(COSMO.Optimizer, 3)
for i in 1:3; build_system(); end
