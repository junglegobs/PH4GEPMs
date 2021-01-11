using Pkg

# Activate environment at current directory
Pkg.activate(dirname(@__FILE__))

# Download and install all required packages
Pkg.instantiate()

# Precompile everyting
Pkg.API.precompile()

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
