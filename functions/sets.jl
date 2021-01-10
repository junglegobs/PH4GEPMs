using PowerSystems

function get_set_of_time_periods()
    return time_periods
end

function get_generator_names(system::System)
    return get_name.(get_components(Generator, system))
end