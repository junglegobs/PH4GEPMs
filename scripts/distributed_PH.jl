# Setup workers
using Distributed
const WORKERS = 3
diff = (nprocs() == nworkers() ? WORKERS : WORKERS - nworkers())
println("Adding $diff worker processes.")
Distributed.addprocs(diff)
# Make sure these workers also have an environment with PH installed
@everywhere using Pkg
for w in workers()
    @spawnat(w, Pkg.activate(joinpath(@__DIR__, "..")))
end

# Setup environments for workers
@everywhere using ProgressiveHedging
const PH = ProgressiveHedging
@everywhere using Ipopt
@everywhere using JuMP
@everywhere include(joinpath(@__DIR__, "..", "functions", "util.jl"))
@everywhere include(joinpath(@__DIR__, "..", "functions", "sets.jl"))
using Logging
logger = configure_logging(console_level = Logging.Error)

# Setup system
years = 1:3
system = build_system()

# Solve 
(n, err, obj, soln, phd) = PH.solve(
    build_scenario_tree(length(years)), # Scenario tree
    build_GEP_sub_problem, # This is the function which builds the model
    1e3, # Penalty term
    system, # This is passed to build_scen_tree
    years; # hopefully also this!
    atol=1e-2, rtol=1e-4, max_iter=500, report=1, # PH solve options
)

# Solve extensive
ef_model = PH.solve_extensive(
    build_scenario_tree(length(years)),
    build_GEP_sub_problem, 
    ()->Ipopt.Optimizer(),
    system, years,
    opt_args=(print_level=0,)
)