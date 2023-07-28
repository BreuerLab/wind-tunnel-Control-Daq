% Used after data collection to trim the data based on the trigger data
% Inputs: results - (n x 7) force transducer data in time
%         trigger_data - time series data from trigger channel on DAQ
% Returns: trimmed_results - results for all values where the trigger
%          voltage was low
function trimmed_results = trim_data(results, trigger_data)
    trimmed_results = zeros(size(results));
    low_trigs_indices = find(trigger_data < 2); % <2 Volts = Digital Low

    if ~(isempty(low_trigs_indices) || low_trigs_indices(1) == 1 ...
            || low_trigs_indices(end) == length(trigger_data))
        trigger_start_frame = low_trigs_indices(1);
        trigger_end_frame = low_trigs_indices(end);
        % disp(trigger_end_frame - trigger_start_frame);
    else
        trigger_start_frame = round(length(results)*(1/4));
        trigger_end_frame = round(length(results)*(3/4));
    end

    trimmed_results = results(trigger_start_frame:trigger_end_frame, :);
    % make time start at t = 0
    trimmed_results(:,1) = trimmed_results(:,1) - trimmed_results(1,1);

    if (length(results) == length(trimmed_results))
        disp("Data was not trimmed.")
    end
end