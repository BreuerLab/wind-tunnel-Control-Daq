function [best_num_bins, best_bin_ind_arr, best_bin_count, best_bin_std] = findBestNumBins(norm_signal, bins_list, minFrames)
    best_num_bins = 0;
    best_bin_count = [];
    best_bin_ind_arr = [];
    best_bin_std = [];
    for num_bins = bins_list
        bins = linspace(0,1,num_bins+1);
        bin_ind_arr = discretize(norm_signal, bins);
    
        % variable preallocation
        [bin_count, bin_std] = deal(zeros(1, num_bins));
    
        for j = 1:num_bins
            bin_indices = find(bin_ind_arr == j);
            bin_count(j) = length(bin_indices);
            bin_std(j) = std(norm_signal(bin_indices));
        end
    
        % ensure at least minFrames images per bin and number of bins is
        % divisible by 5
        if min(bin_count) > minFrames && mod(num_bins,5) == 0
            best_num_bins = num_bins;
            best_bin_count = bin_count;
            best_bin_ind_arr = bin_ind_arr;
            best_bin_std = bin_std*100; % rescale to percent
        end
    end
end