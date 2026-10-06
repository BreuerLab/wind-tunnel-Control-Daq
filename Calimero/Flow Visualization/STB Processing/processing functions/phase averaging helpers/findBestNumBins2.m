function [best_num_bins, best_offset, best_bin_ind_arr, best_bin_count, best_bin_std] = findBestNumBins2(norm_signal, bins_list, minFrames, num_shifts)
    if nargin < 4
        num_shifts = 10; % Number of offset steps to test across one bin width
    end

    best_num_bins = 0;
    best_offset = 0;
    best_bin_count = [];
    best_bin_ind_arr = [];
    best_bin_std = [];
    min_avg_std = inf;

    % -------------------------------------
    % Loop through all bin numbers
    % -------------------------------------
    for num_bins = bins_list
        bin_width = 1 / num_bins;
        % Generate phase shifts across one bin width
        offsets = linspace(0, bin_width * (1 - 1/num_shifts), num_shifts);

        % -------------------------------------
        % Loop through all offsets
        % -------------------------------------
        for offset = offsets
            % Circularly shift signal to move boundary split points away from edges
            shifted_signal = mod(norm_signal - offset, 1);

            bins = linspace(0, 1, num_bins + 1);
            bins(end) = 1 + eps; % Prevent edge case where value equals 1
            bin_ind_arr = discretize(shifted_signal, bins);

            [bin_count, bin_std] = deal(zeros(1, num_bins));

            % -------------------------------------
            % Loop through all bins
            % -------------------------------------
            for j = 1:num_bins
                bin_indices = (bin_ind_arr == j);
                bin_count(j) = sum(bin_indices);

                if bin_count(j) > 0
                    % Range is measured on shifted values to avoid boundary artifacts
                    bin_std(j) = range(shifted_signal(bin_indices)) * num_bins * 100;
                else
                    bin_std(j) = inf;
                end
            end

            avg_std = mean(bin_std);

            % Optimization criteria matching
            if min(bin_count) >= minFrames && avg_std < min_avg_std
                min_avg_std = avg_std;
                best_num_bins = num_bins;
                best_offset = offset;
                best_bin_count = bin_count;
                best_bin_ind_arr = bin_ind_arr;
                best_bin_std = bin_std;
            end
        end
    end
end