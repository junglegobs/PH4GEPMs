using PowerSystems
using ProgressiveHedging
using JuMP
using Ipopt
using Logging
logger = configure_logging(console_level = Logging.Error)

opts = Dict(
    :years => 1:2,
    :optimizer=>optimizer_with_attributes(Ipopt.Optimizer, "print_level" => 0, "tol" => 1e-4),
    :models=>Dict{PH.ScenarioID,Model}()
)
system = build_system()

(n, err, obj, soln, phd) = PH.solve(
    build_scenario_tree(length(opts[:years])), # Scenario tree
    build_GEP_sub_problem, # This is the function which builds the model
    1e3, # Penalty term
    system, # This is passed to build_scen_tree
    opts; # hopefully also this!
    atol=1e-2, rtol=1e-4, max_iter=500, report=1, # PH solve options
)

# Compare to extensive solve
ef_model = PH.solve_extensive(
    build_scenario_tree(length(opts[:years])),
    build_GEP_sub_problem, 
    ()->Ipopt.Optimizer(),
    system, years,
    opt_args=(print_level=0,)
)

# ... and my extensive solve
m = build_GEP(system, years)
optimize!(m)

print(
"""
Progressive hedging objective: $obj
Extensive model objective: $(objective_value(ef_model))
My extensive model objective: $(objective_value(m))
"""
)