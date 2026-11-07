function [shifted_sig, lag_in_samples, corr, lags] = align_signals(sig1, sig2)
% Shift sig2 onto sig1 by the lag of the peak of their circular
% cross-correlation. The signals are one period (wingbeat) on the same
% grid, so the correlation is circular, consistent with the circshift
% that applies the lag: every lag uses all n samples.
%
%   corr(k) = sum_m s1(m) * s2(m - lags(k)), indices mod n
%
% with s1, s2 the signals normalized to zero mean and unit std, so
% corr / (n - 1) is 1 where the shapes match exactly. Lags run from
% -floor(n/2) to ceil(n/2) - 1 samples (half a period either way).
% Also returns corr and lags, e.g. for plotting (phaseAvg_UI "Corr").

    sig1 = sig1(:)';
    sig2 = sig2(:)';
    n = numel(sig1);

    % normalize signals to have mean of zero and std of 1
    sig1_norm = (sig1 - mean(sig1)) / std(sig1);
    sig2_norm = (sig2 - mean(sig2)) / std(sig2);

    % circular cross-correlation
    lags = -floor(n/2):(ceil(n/2) - 1);
    corr = zeros(size(lags));
    for k = 1:numel(lags)
        corr(k) = sum(sig1_norm .* circshift(sig2_norm, lags(k)));
    end

    % lag at the maximum correlation (samples)
    [~, max_idx] = max(corr);
    lag_in_samples = lags(max_idx);

    shifted_sig = circshift(sig2, lag_in_samples);
end
