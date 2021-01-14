# Setup workers
using Distributed
const WORKERS = 15
diff = (nprocs() == nworkers() ? WORKERS : WORKERS - nworkers())
println("Adding $diff worker processes.")
Distributed.addprocs(diff)

# Setup environments for workers
@everywhere using ProgressiveHedging
const PH = ProgressiveHedging
@everywhere using Ipopt
@everywhere using CSDP
@everywhere using COSMO
@everywhere using JuMP
@everywhere include(joinpath(@__DIR__, "..", "functions", "util.jl"))
@everywhere include(joinpath(@__DIR__, "..", "functions", "sets.jl"))
using Logging
logger = configure_logging(console_level = Logging.Error)

# Setup system
opts = Dict(
    :years => 1:3,
    :optimizer => optimizer_with_attributes(CSDP.Optimizer, "printlevel" => 0)
    # optimizer_with_attributes(COSMO.Optimizer, "verbose" => true, "eps_abs" => 1e-1, "max_iter" => 10_000)
)
system = build_system()

# Solve 
(n, err, obj, soln, phd) = PH.solve(
    build_scenario_tree(length(opts[:years])), # Scenario tree
    build_GEP_sub_problem, # This is the function which builds the model
    1e3, # Penalty term
    system, # This is passed to build_scen_tree
    opts; # hopefully also this!
    atol=1e-1, rtol=1e-3, max_iter=500, report=1, # PH solve options
)

# Solve extensive
t = @elapsed ef_model = PH.solve_extensive(
    build_scenario_tree(length(opts[:years])),
    build_GEP_sub_problem, 
    ()->CSDP.Optimizer(),
    system, opts,
    opt_args=NamedTuple()
)