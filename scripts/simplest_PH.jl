using PowerSystems
using ProgressiveHedging
using JuMP
using Logging
logger = configure_logging(console_level = Logging.Error)

years = 1:2
system = build_system()

(n, err, obj, soln, phd) = PH.solve(
    build_scenario_tree(length(years)), # Scenario tree
    build_GEP_sub_problem, # This is the function which builds the model
    1e3, # Penalty term
    system, # This is passed to build_scen_tree
    years; # hopefully also this!
    atol=1e-2, rtol=1e-4, max_iter=500, report=1, # PH solve options
)

# Compare to extensive solve
ef_model = PH.solve_extensive(
    build_scenario_tree(length(years)),
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