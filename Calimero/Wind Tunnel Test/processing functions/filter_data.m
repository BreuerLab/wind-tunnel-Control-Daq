% Author: Ronan Gissler
% Last updated: October 2023

% Inputs:
% results - (n x 6) force transducer data
% frame_rate - DAQ data sampling rate (Hz)

% Outputs:
% filtered_results - (n x 6) filtered force transducer data
function filtered_results = filter_data(results, frame_rate, fc)
    num_axes = min(size(results));
    % cutoff should be ten times higher than flapping frequency, don't want
    % to filter the data too much, then we'd have no data
    fs = frame_rate;

    [z, p, k] = butter(6, fc/(fs/2)); % zeros, poles, and gains

    % Convert into Second-Order Sections (prevents numerical issues with
    % more aggressive filtering)
    [sos, g] = zp2sos(z, p, k);

    filtered_results = zeros(size(results));
    for i = 1:num_axes
        filtered_results(i,:) = filtfilt(sos,g,results(i,:));
    end
end