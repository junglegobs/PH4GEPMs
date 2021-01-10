# Fill me with frequently used functions
using CSV
using DataFrames

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

function build_system()
    system = System(1.0)
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
    Peak = ThermalStandard(
        name = "Peak",
        available = true,
        status = true,
        bus = Italy,
        active_power = 0.40,
        reactive_power = 0.010,
        rating = 0.85, # Use as availability factor
        prime_mover = PrimeMovers.ST, # Steam turbine
        fuel = ThermalFuels.NATURAL_GAS,
        active_power_limits = nothing,
        reactive_power_limits = nothing,
        time_limits = nothing,
        ramp_limits = nothing,
        operation_cost = TwoPartCost(0.112, 46.4), # Variable and fixed costs in M euros and GW(h)
        base_power = 100.0,
    )
end

function process_time_series()
    df = DataFrame(T = 1:8760)
    name_map = Dict(
        "Load" => "IT_2025_Load.csv",
        "Solar" => "IT_2020_Solar.csv",
        "WindOff" => "IT_2020_WindOff.csv",
        "WindOn" => "IT_2020_WindOn.csv",
    )
    for (ts_name, ts_csv_name) in name_map
        temp = CSV.read(joinpath(ROOT_DIR, "data", ts_csv_name), DataFrame)
        name_pairs = [Symbol(i) => Symbol("$(ts_name)_$i") for i in 1:35]
        rename!(temp, name_pairs)
        df = hcat(df, temp[:, last.(name_pairs)])
    end

    return df
end

