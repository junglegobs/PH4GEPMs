# Fill me with frequently used functions
using CSV, Dates, DataFrames, PowerSystems

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
        ts_name => DataFrame(T = time_periods)
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
        rename!(df, name_pairs)
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