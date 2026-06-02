function [shifted_sig, lag_in_samples] = align_signals(sig1, sig2)

    % normalize signals to have mean of zero and std of 1
    sig1_norm = (sig1 - mean(sig1)) / std(sig1);
    sig2_norm = (sig2 - mean(sig2)) / std(sig2);

    % Compute Cross-Correlation
    [corr, lags] = xcorr(sig1_norm, sig2_norm);
    
    % Find the index of the maximum correlation
    [~, max_idx] = max(corr);
    
    % 3. Extract the lag at the maximum correlation
    % lags are in terms of samples
    lag_in_samples = lags(max_idx);

    shifted_sig = circshift(sig2, lag_in_samples);
end