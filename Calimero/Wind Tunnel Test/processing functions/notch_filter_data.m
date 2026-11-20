% Author: Ronan Gissler
% Last updated: November 2026

% Removes narrow frequency bands (e.g. structural resonances of the wings,
% such as the first spanwise bending mode) from the data with zero-phase
% band-stop (notch) Butterworth filters, leaving the content below and
% above each band untouched.

% Inputs:
% results - (m x n) data, one channel per row (same layout as filter_data)
% frame_rate - DAQ data sampling rate (Hz)
% f_notch - centre frequency/frequencies of the bands to remove (Hz),
%           scalar or vector (one band per entry)
% bw - full width of each band (Hz), scalar (same for every band) or a
%      vector the same length as f_notch
% rows - (optional) rows of results to filter, all rows by default. The
%        other rows are returned unchanged.

% Outputs:
% filtered_results - (m x n) notch filtered data
function filtered_results = notch_filter_data(results, frame_rate, f_notch, bw, rows)
    if nargin < 5 || isempty(rows)
        rows = 1:size(results, 1);
    end
    if isscalar(bw)
        bw = bw * ones(size(f_notch));
    end

    fs = frame_rate;
    filtered_results = results;

    for j = 1:length(f_notch)
        f_lo = f_notch(j) - bw(j)/2;
        f_hi = f_notch(j) + bw(j)/2;
        if f_lo <= 0 || f_hi >= fs/2
            error("notch_filter_data: band " + f_lo + "-" + f_hi + ...
                " Hz must lie between 0 and the Nyquist frequency (" + fs/2 + " Hz)")
        end

        % 4th order prototype -> 8th order band-stop, for sharp band edges
        % so the wingbeat harmonics just outside the band survive (a 2nd
        % order prototype still cut a harmonic 2 Hz outside a 10 Hz band
        % to ~85% amplitude). filtfilt doubles the attenuation (band edges
        % f_lo/f_hi end up at -6 dB) and removes the phase shift.
        % Second-order sections keep a narrow band at a high sampling rate
        % numerically stable.
        [z, p, k] = butter(4, [f_lo f_hi]/(fs/2), 'stop');
        [sos, g] = zp2sos(z, p, k);

        for i = rows
            filtered_results(i,:) = filtfilt(sos, g, filtered_results(i,:));
        end
    end
end
