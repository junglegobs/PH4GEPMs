# Fill me with frequently used functions
using CSV, Dates, DataFrames, PowerSystems, TimeSeries, JuMP
using Cbc, Ipopt, ProgressiveHedging, Gurobi, COSMO
PH = ProgressiveHedging
ROOT_DIR = abspath(@__DIR__, "..")

"""
	mkrootdirs(dir::String)

Recursively creates directories if these do not exist yet.
"""
function mkrootdirs(dir::String)
    dirVec = split(dir, "/")
    dd = "/"
    for d in dirVec[2:end]
        dd = joinpath(dd, d)
        if isdir(dd) == false
            mkdir(dd)
        end
    end
end

function process_time_series()
    ts_names = ["Load", "Solar", "WindOff", "WindOn"]
    ts_dict = Dict(
        ts_name => DataFrame(T = get_set_of_time_periods(all=true))
        for ts_name in ts_names
    )
    name_map = Dict(
        "Load" => "IT_2025_Load.csv",
        "Solar" => "IT_2020_Solar.csv",
        "WindOff" => "IT_2020_WindOff.csv",
        "WindOn" => "IT_2020_WindOn.csv",
    )
    norm_factors = Dict(
        "Load" => 1000,
        "Solar" => 100,
        "WindOff" => 100,
        "WindOn" => 100,
    )
    # TODO: Get rid of hard coded 1:35 bit
    for (ts_name, ts_csv_name) in name_map
        file = joinpath(ROOT_DIR, "data", ts_csv_name)
        # s = replace(readstring(file), ",", ".")
        df = CSV.read(file, DataFrame;
            typemap=Dict(String=>Float64), 
            types=Dict(Symbol(i) => Float64 for i in 1:35),
            delim=";", decimal=','
        )
        name_pairs = [Symbol(i) => Symbol("$(ts_name)_$i") for i in 1:35]
        DataFrames.rename!(df, name_pairs)
        ts_dict[ts_name] = hcat(
            ts_dict[ts_name], df[:, last.(name_pairs)] ./ norm_factors[ts_name]
        )
    end

    return ts_dict
end

function build_system()
    system = System(1.0; time_series_in_memory = true)
    Italy = Bus(
        number = 1,
        name = "Italy",
        bustype = nothing,
        angle = nothing,
        magnitude = nothing,
        voltage_limits = nothing,
        base_voltage = nothing,
        area = nothing,
        load_zone = nothing
    )
    Load = PowerLoad(
        name = "Load",
        available = true,
        bus = Italy,
        model = nothing,
        active_power = 1.0,
        reactive_power = 0.0,
        base_power = 1.0,
        max_active_power = 1.0,
        max_reactive_power = 0.0,
        services = Service[],
        dynamic_injector = nothing,
        # time_series_container = SingleTimeSeries("Load", ts_dict["Load"];
        #     timestamp=:T
        # )
    )
    Peak = ThermalStandard(
        name = "Peak",
        available = true,
        status = true,
        bus = Italy,
        active_power = 1.0,
        reactive_power = 0.0,
        rating = 1.0, # Use as availability factor
        prime_mover = PrimeMovers.ST, # Steam turbine
        fuel = ThermalFuels.NATURAL_GAS,
        active_power_limits = (min = 0.0, max = 1.0),
        reactive_power_limits = (min = 0.0, max = 0.00),
        time_limits = nothing,
        ramp_limits = nothing,
        operation_cost = TwoPartCost(0.112, 46.4), # Variable and fixed costs in M euros and GW(h)
        base_power = 0.0,
    )
    Base = ThermalStandard(
        name = "Base",
        available = true,
        status = true,
        bus = Italy,
        active_power = 1.0,
        reactive_power = 0.0,
        rating = 1.0, # Use as availability factor
        prime_mover = PrimeMovers.ST, # Steam turbine
        fuel = ThermalFuels.NATURAL_GAS,
        active_power_limits = (min = 0.0, max = 1.0),
        reactive_power_limits = (min = 0.0, max = 0.00),
        time_limits = nothing,
        ramp_limits = nothing,
        operation_cost = TwoPartCost(0.054, 82.120), # Variable and fixed costs in M euros and GW(h)
        base_power = 0.0,
    )

    add_component!(system, Italy)
    add_component!(system, Load)
    add_component!(system, Peak)
    add_component!(system, Base)

    ts_dict = process_time_series()
    add_time_series!(system, Load, SingleTimeSeries(
            "Load", ts_dict["Load"]; timestamp=:T
        )
    )

    return system
end

function build_GEP(system::System, years=[1])
    m = Model(Cbc.Optimizer)
    m.ext[:variables] = Dict{Symbol,Any}()
    m.ext[:constraints] = Dict{Symbol,Any}()

    G = get_generator_names(system)
    Y = years
    T = get_set_of_time_periods()

    idxLoad = [Symbol("Load_$i") for i in Y]
    load = get_time_series_array(
        SingleTimeSeries, get_component(StaticLoad, system, "Load"), "Load"
    )[idxLoad]

    # Create variables
    q = m.ext[:variables][:q] = @variable(m, 
        q[g in G, y in Y, t in T] >= 0
    )
    k = m.ext[:variables][:k] = @variable(m, 
        k[g in G] >= 0
    )
    ls = m.ext[:variables][:ls] = @variable(m, 
        ls[y in Y, t in T] >= 0
    )

    # Power balance
    power_balance = m.ext[:constraints][:power_balance] = @constraint(m, 
        [y in Y, t in T],
        sum(q[g,y,t] for g in G) 
        == 
        first(values(load[t][Symbol("Load_$y")])) - ls[y,t]
    )

    # Limit generation
    limit_gen = m.ext[:constraints][:limit_gen] = @constraint(m,
        [g in G, y in Y, t in T],
        q[g,y,t] <= k[g]
    )

    # Objective
    @objective(m, Min, 
        + sum(q[get_name(g),y,t] * get_cost(get_variable(get_operation_cost(g)))
            for g in get_components(Generator, system), y in Y, t in T
        ) / length(Y)
        + sum(ls[y,t] * get_VOLL() for y in Y, t in T) / length(Y)
        + sum(k[get_name(g)] * get_fixed(get_operation_cost(g))
            for g in get_components(Generator, system)
        )
    )

    return m
end

function build_GEP_sub_problem(
        scenario_id::PH.ScenarioID, 
        system::System,
        years,
    )
    m = Model(get_optimizer(;sub_problem=true, preferred="Gurobi"))
    m.ext[:variables] = Dict{Symbol,Any}()
    m.ext[:constraints] = Dict{Symbol,Any}()

    T = get_set_of_time_periods()
    G = get_generator_names(system)

    yidx = years[scenario_id.value+1]
    load = get_time_series_array(
        SingleTimeSeries, get_component(StaticLoad, system, "Load"), "Load"
    )[Symbol("Load_$(yidx)")]

    # Create variables
    q = m.ext[:variables][:q] = @variable(m, 
        q[g in G, t in T] >= 0
    )
    ls = m.ext[:variables][:ls] = @variable(m, 
        ls[t in T] >= 0
    )
    k = m.ext[:variables][:k] = @variable(m, 
        k[g in G] >= 0
    )
    dispatch = vcat(q.data[:], ls.data[:])
    investments = k.data[:]

    # Power balance
    power_balance = m.ext[:constraints][:power_balance] = @constraint(m, 
        [t in T],
        sum(q[g,t] for g in G) == first(values(load[t])) - ls[t]
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
        + sum(ls[t] * get_VOLL() for t in T)
        + sum(k[get_name(g)] * get_fixed(get_operation_cost(g))
            for g in get_components(Generator, system)
        )
    )

    vdict = Dict{PH.StageID, Vector{JuMP.VariableRef}}(
        PH.stid(1) => investments,
        PH.stid(2) => dispatch
    )

    return JuMPSubproblem(m, scenario_id, vdict)
end

function build_scenario_tree(
        num_years::Int
    )
    probs = [1 / num_years for i in 1:num_years]
    tree = PH.ScenarioTree()
    for y in 1:num_years
        PH.add_leaf(tree, tree.root, probs[y])
    end
    return tree
end

function get_set_of_time_periods(;all::Bool=false)
    # Any time in the year 2018
    all == true && return range(DateTime(2018); length=8760, step=Hour(1))
    return range(DateTime(2018); length=24, step=Hour(1))
end

function get_generator_names(system::System)
    return get_name.(get_components(Generator, system))
end


function get_optimizer(;sub_problem=true, preferred="Gurobi")
    verbosity = sub_problem ? 0 : 1
    if preferred == "Gurobi" && haskey(ENV, "GUROBI_HOME")
        return optimizer_with_attributes(
            Gurobi.Optimizer, "OutputFlag" => verbosity, 
            "OptimalityTol" => 1e-4
        )
    elseif preferred == "COSMO"
        return optimizer_with_attributes(
            COSMO.Optimizer, "verbose" => false, 
            "eps_abs" => 1e-1, "max_iter" => 10_000
        )
    elseif preferred == "Cbc"
        return optimizer_with_attributes(
            Cbc.Optimizer, "logLevel" => verbosity
        )
    else
        return optimizer_with_attributes(Ipopt.Optimizer, 
            "print_level" => verbosity, "tol" => 1e-2
        )
    end
end

get_VOLL() = 10.0

;