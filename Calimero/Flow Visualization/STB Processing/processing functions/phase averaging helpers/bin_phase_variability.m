function bin_var = bin_phase_variability(norm_signal, bin_ind_arr, num_bins)
% Range of phase values within each bin, as a percentage of the bin width
% (same quantity findBestNumBins2 returns as bin_std).
%
% norm_signal - phase of each frame in [0, 1)
% bin_ind_arr - bin each frame was assigned to (1..num_bins)
%
% The range is taken around the circle (1 minus the largest gap between
% sorted phases, including the gap across 1 -> 0), so a bin that straddles
% the 0/1 seam is not inflated. For bins narrower than half a cycle this
% matches findBestNumBins2, which measures the range on the offset-shifted
% signal. Empty bins give NaN.

norm_signal = double(norm_signal(:));
bin_ind_arr = double(bin_ind_arr(:));
bin_var = NaN(1, num_bins);

for j = 1:num_bins
    p = sort(mod(norm_signal(bin_ind_arr == j), 1));
    p = p(isfinite(p));
    if isempty(p)
        continue
    end
    gaps = [diff(p); p(1) + 1 - p(end)];
    bin_var(j) = (1 - max(gaps)) * num_bins * 100;
end
end
