using PowerSystems
using ProgressiveHedging
using JuMP
using Cbc
using Logging
logger = configure_logging(console_level = Logging.Error)

system = build_system()

function build_GEP(system::System)
    m = Model(Cbc.Optimizer)
    m.ext[:variables] = Dict{Symbol,Any}()
    m.ext[:constraints] = Dict{Symbol,Any}()

    T = get_set_of_time_periods()
    G = get_generator_names(system)

    load = get_time_series_array(
        SingleTimeSeries, get_component(StaticLoad, system, "Load"), "Load"
    )[:Load_1]

    # Create variables
    q = m.ext[:variables][:q] = @variable(m, 
        q[g in G, t in T] >= 0
    )
    k = m.ext[:variables][:k] = @variable(m, 
        k[g in G] >= 0
    )

    # Power balance
    power_balance = m.ext[:constraints][:power_balance] = @constraint(m, 
        [t in T],
        sum(q[g,t] for g in G) == first(values(load[t]))
    )

    # Limit generation
    limit_gen = m.ext[:constraints][:limit_gen] = @constraint(m,
        [g in G, t in T],
        q[g,t] <= k[g]
    )

    # Objective
    @objective(m, Min, 
        + sum(q[get_name(g),t] * get_cost(get_variable(get_operation_cost(g)))
            for g in get_components(Generator, system), t in T
        )
        + sum(k[get_name(g)] * get_fixed(get_operation_cost(g))
            for g in get_components(Generator, system)
        )
    )
    sum(k[get_name(g)] * get_fixed(get_operation_cost(g))
        for g in get_components(Generator, system)
    )

    return m
end

m = build_GEP(system)
optimize!(m)