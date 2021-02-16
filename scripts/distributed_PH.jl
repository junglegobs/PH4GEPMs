# Setup workers
using Distributed
WORKERS = 2
diff = (nprocs() == nworkers() ? WORKERS : WORKERS - nworkers())
println("Adding $diff worker processes.")
Distributed.addprocs(diff)

@everywhere include(joinpath(@__DIR__, "..", "functions", "util.jl"))
PH = ProgressiveHedging
using Logging
logger = configure_logging(console_level = Logging.Error)

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
    years; # hopefully also this!
    atol=1e-2, rtol=1e-4, max_iter=500, report=1, # PH solve options
);
