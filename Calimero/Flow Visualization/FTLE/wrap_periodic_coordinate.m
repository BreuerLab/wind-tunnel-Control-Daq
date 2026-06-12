function wrapped = wrap_periodic_coordinate(query, lower_bound, upper_bound)
%WRAP_PERIODIC_COORDINATE Wrap finite coordinates into periodic bounds.

wrapped = query;
period = upper_bound - lower_bound;

if period <= 0 || ~isfinite(period)
    return
end

outside = isfinite(query) & (query < lower_bound | query > upper_bound);
wrapped(outside) = lower_bound + mod(query(outside) - lower_bound, period);
end
