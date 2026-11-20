function rate = get_daq_rate(params, time)
    % DAQ sampling rate (Hz) for a recording.
    %
    % params - struct loaded from the session's experiment_params file (the
    %          workspace of run_experiment.m / benchtop_test.m, which
    %          includes 'rate'), or [] if not available
    % time   - (optional) the recording's time column (results(:,1) of an
    %          experiment file), used to check the rate, or as a fallback
    %          when params has no rate
    %
    % The params rate is used whenever it exists; a warning is given if the
    % time column disagrees with it by more than 1%.
    rate_params = NaN;
    if isstruct(params) && isfield(params, 'rate') && ~isempty(params.rate)
        rate_params = double(params.rate);
    end

    rate_time = NaN;
    if nargin > 1 && numel(time) > 1
        dt = median(diff(double(time(:))));
        if dt > 0
            rate_time = 1 / dt;
        end
    end

    if isfinite(rate_params)
        rate = rate_params;
        if isfinite(rate_time) && abs(rate_time - rate_params) / rate_params > 0.01
            warning("get_daq_rate:mismatch",...
                "Params rate %g Hz but the recording's time column gives %.1f Hz; using %g Hz",...
                rate_params, rate_time, rate_params);
        end
    elseif isfinite(rate_time)
        rate = round(rate_time);
        warning("get_daq_rate:noParamsRate",...
            "No rate in the experiment params; using %g Hz from the recording's time column", rate);
    else
        error("get_daq_rate:unknown",...
            "No rate in the experiment params and no time column to measure it from");
    end
end
