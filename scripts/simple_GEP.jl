using PowerSystems
using ProgressiveHedging
using COSMO
using JuMP
using Logging
logger = configure_logging(console_level = Logging.Error)

function run_simple_GEP(opts)
    println("Building system...")
    t = @elapsed (system = build_system())
    println("Time: $t")
    println("Building optimization model...")
    t = @elapsed (m = build_GEP(system, opts))
    println("Time: $t")
    println("Optimizing...")
    t = @elapsed (optimize!(m))
    println("Time: $t")
    return system, m
end

opts = Dict(
    :years => [1],
    :optimizer => optimizer_with_attributes(COSMO.Optimizer, 
        "eps_rel" => 1e-3, "verbose_timing" => true, 
        "rho" => 10.0, "max_iter" => 10_000,
        "eps_prim_inf" => 1e-3,
        "eps_dual_inf" => 1e-3
    )
)

system, m = run_simple_GEP(opts)
@show backend(m).optimizer.model.optimizer.results.times