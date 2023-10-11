function filtered_results = filter_data(results, frame_rate)
    fc = 50; % cutoff frequency
    fs = frame_rate;
    [b,a] = butter(6,fc/(fs/2));
    filtered_results = zeros(size(results));
    for i = 1:6
        filtered_results(:,i) = filtfilt(b,a,results(:, i));
    end
end