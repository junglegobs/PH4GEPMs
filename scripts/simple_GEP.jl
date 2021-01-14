using PowerSystems
using ProgressiveHedging
using CSDP
using JuMP
using Logging
logger = configure_logging(console_level = Logging.Error)

system = build_system()

opts = Dict(
    :years => [1,2],
    :optimizer => optimizer_with_attributes(CSDP.Optimizer, "printlevel" => 1)
)
m = build_GEP(system, opts)
optimize!(m)