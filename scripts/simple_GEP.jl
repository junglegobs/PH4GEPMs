using PowerSystems
using ProgressiveHedging
using Cbc
using JuMP
using Logging
logger = configure_logging(console_level = Logging.Error)

system = build_system()

opts = Dict(
    :years => [1,2],
    :optimizer => get_optimizer(sub_problem=false, preferred = "Cbc"),
)
m = build_GEP(system, opts)
optimize!(m)