using SIIPExamples;
using PowerSystems;
using D3TypeTrees;
IS = PowerSystems.IS

BASE_DIR = abspath(joinpath(dirname(Base.find_package("PowerSystems")), ".."))
include(joinpath(BASE_DIR, "test", "data_5bus_pu.jl")) #.jl file containing 5-bus system data
nodes_5 = nodes5() # function to create 5-bus buses

sys = System(
    100.0,
    nodes_5,
    vcat(thermal_generators5(nodes_5), renewable_generators5(nodes_5)),
    loads5(nodes_5),
    branches5(nodes_5),
)



loads = collect(get_components(PowerLoad, sys))
for (l, ts) in zip(loads, load_timeseries_DA[2])
    add_time_series!(
        sys,
        l,
        Deterministic(
            "activepower",
            Dict(TimeSeries.timestamp(load_timeseries_DA[2][1])[1] => ts),
        ),
    )
end

ts = get_time_series_values(Deterministic, loads[1], ts_names[1])