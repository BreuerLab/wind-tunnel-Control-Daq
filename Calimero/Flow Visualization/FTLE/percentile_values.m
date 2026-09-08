function values = percentile_values(data, percentiles)
%PERCENTILE_VALUES Return percentile values using linear interpolation.

data = sort(data(:));
percentiles = min(100, max(0, percentiles(:)));

if isempty(data)
    values = NaN(size(percentiles));
    return
end

rank = 1 + (percentiles / 100) * (numel(data) - 1);
lower_idx = floor(rank);
upper_idx = ceil(rank);
weight = rank - lower_idx;

values = data(lower_idx) .* (1 - weight) + data(upper_idx) .* weight;
values = reshape(values, size(percentiles));
end
