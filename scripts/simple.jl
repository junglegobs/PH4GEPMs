using PowerSystems
using ProgressiveHedging

system_data = System(joinpath(DATA_DIR, "matpower/case5_re.m"))
add_time_series!(system_data, joinpath(DATA_DIR,"forecasts/5bus_ts/timeseries_pointers_da.json"))
to_json(system_data, "system_data.json")