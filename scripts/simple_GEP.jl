using PowerSystems
using ProgressiveHedging
using JuMP
using Logging
logger = configure_logging(console_level = Logging.Error)

system = build_system()

m = build_GEP(system, [1,2])
optimize!(m)