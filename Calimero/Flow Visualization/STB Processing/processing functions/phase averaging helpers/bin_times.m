function t = bin_times(num_bins, period, bin_placement)
% BIN_TIMES Actual time of each phase bin within the cycle.
%
%   t = bin_times(num_bins, period)                 % nominal: (k-1)*dt
%   t = bin_times(num_bins, period, bin_placement)  % actual mean phase
%
%   The phase average of a bin represents the flow at the MEAN phase of
%   its frames, not at the bin centre. bin_placement (saved by
%   phase_avg_STB, from frame_to_bin) is that mean phase minus the bin
%   centre, in % of a bin width. This returns
%       t_k = (k - 1 + bin_placement(k)/100) * period / num_bins
%   i.e. the existing convention (bin k at (k-1)*dt) corrected by the
%   placement. Missing / NaN placements (empty bins, older files) count
%   as 0, which reproduces the nominal uniform times. Column vector.

dt = period / num_bins;
p  = zeros(num_bins, 1);
if nargin >= 3 && ~isempty(bin_placement) && numel(bin_placement) == num_bins
    p = double(bin_placement(:));
    p(~isfinite(p)) = 0;
end
t = ((0:num_bins-1)' + p / 100) * dt;
end
