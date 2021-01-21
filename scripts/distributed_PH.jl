# Setup workers
using Distributed
const WORKERS = 4
diff = (nprocs() == nworkers() ? WORKERS : WORKERS - nworkers())
println("Adding $diff worker processes.")
Distributed.addprocs(diff)

# Setup environments for workers
@everywhere using ProgressiveHedging
const PH = ProgressiveHedging
@everywhere using COSMO
@everywhere using SCS
@everywhere using Cbc
@everywhere using JuMP
@everywhere include(joinpath(@__DIR__, "..", "functions", "util.jl"))
@everywhere include(joinpath(@__DIR__, "..", "functions", "sets.jl"))
@everywhere using Logging
@everywhere logger = configure_logging(console_level = Logging.Error)

# Setup system
opts = Dict(
    :years => 1:4,
    :models => Dict{Int,Model}(),
    :optimizer => optimizer_with_attributes(COSMO.Optimizer, 
        "eps_rel" => 1e-3, "verbose_timing" => true, 
        "rho" => 10.0, "max_iter" => 10_000,
        "eps_prim_inf" => 1e-3,
        "eps_dual_inf" => 1e-3,
        "verbose" => false,
    )
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
    ()->Cbc.Optimizer(),
    system, opts,
    opt_args=NamedTuple()
)