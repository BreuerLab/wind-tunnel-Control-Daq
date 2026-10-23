function centroid = mask_vortex_centroid(centroid, vortX_avg, case_label)
% Blank out omega_x centroid values (wx_y, wx_z) in phase bins where the
% net omega_x is too small for the centroid to mean anything.
%
% The centroid is int(y*wx dA) / int(wx dA). wx is signed, so when the
% positive and negative vorticity in the plane nearly cancel the
% denominator goes to zero and the ratio can land far outside the field
% of view (e.g. y/L = -35). vortX_avg (plane-mean wx over the same trimmed
% plane, saved next to the centroids) is proportional to that denominator.
%
% Bins with |vortX_avg| below MIN_FRACTION of its largest value over the
% cycle are set to NaN. Time-averaged (single value) cases are untouched.

MIN_FRACTION = 0.1; % raise to mask more bins, lower to keep more

centroid = double(centroid);
vortX_avg = double(vortX_avg(:)');
if numel(centroid) <= 1 || numel(vortX_avg) ~= numel(centroid)
    return
end

shape = size(centroid);
centroid = centroid(:)';
too_small = abs(vortX_avg) < MIN_FRACTION * max(abs(vortX_avg)) | isnan(vortX_avg);
centroid(too_small) = NaN;
centroid = reshape(centroid, shape);

if any(too_small)
    if nargin < 3
        case_label = "";
    end
    fprintf("%s: %d of %d bins masked for the wx centroid (net wx below %g%% of its max)\n",...
        case_label, nnz(too_small), numel(too_small), 100*MIN_FRACTION);
end
end
