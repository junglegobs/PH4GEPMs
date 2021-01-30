using Pkg
cd(@__DIR__)

# Activate environment at current directory
Pkg.activate(dirname(@__FILE__))

# Download and install all required packages
Pkg.instantiate()

# Constant values which may be useful
using Dates
using ProgressiveHedging
const PH = ProgressiveHedging
const ROOT_DIR = @__DIR__
const time_periods =  DateTime(2018):Hour(1):DateTime(2019)-Hour(1)
const VOLL = 10 # Million euros per GWh

# Include other scripts
using Revise # So I can do includet
for (root, subdirs, files) in walkdir(abspath(@__DIR__, "functions"))
    for f in (f for f in files if match(r"^\w+\.jl",f) != nothing)
        includet(joinpath(root,f))
    end
end

# Other stuff
ENV["JULIA_DEBUG"] = "Main" # Show debug messages for packages

# Potential solvers to try out
# Pkg.add("SCS") # splitting cone solver. SCS can solve linear programs, second-order cone programs, semidefinite programs, exponential cone programs, and power cone programs.
# Pkg.add("CSDP") # Cbc but for quadratic problems, is a bit more involved for installation, see here: https://github.com/jump-dev/CSDP.jl
# Pkg.add("ECOS") # https://github.com/embotech/ecos, seems proprietary
# https://github.com/jump-dev/DSDP.jl
# https://github.com/jump-dev/SDPA.jl
# https://github.com/jump-dev/Pavito.jl # requires specifying solvers
# https://www.maths.ed.ac.uk/hall/HiGHS/ # Linear MILPs looks like it could outperform Cbc? Looks newer at least
# https://osqp.org/docs/solver/index.html 
# https://github.com/ds4dm/Tulip.jl#usage # Pure Julia, but only allows linear problems
# https://github.com/oxfordcontrol/COSMO.jl # Pure julia, quadratic problems!!!