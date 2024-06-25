% Author: Ronan Gissler
% Last updated: October 2023

% Inputs:
% results - (n x 6) force transducer data
% frame_rate - DAQ data sampling rate (Hz)

% Outputs:
% filtered_results - (n x 6) filtered force transducer data
function filtered_results = filter_data(results, frame_rate, fc)
    % cutoff should be ten times higher than flapping frequency, don't want
    % to filter the data too much, then we'd have no data
    fs = frame_rate;
    [b,a] = butter(6,fc/(fs/2));
    filtered_results = zeros(size(results));
    for i = 1:6
        filtered_results(i, :) = filtfilt(b,a,results(i, :));
    end
end