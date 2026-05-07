function data = nanToMedian(data)
    data(isnan(data)) = median(data,"all");
end