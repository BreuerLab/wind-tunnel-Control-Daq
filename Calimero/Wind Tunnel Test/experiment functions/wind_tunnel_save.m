% Save wind tunnel struct variable so that we know the air properties
% for this trial
%
% AFAM_state.mat is rewritten by the AFAM PC while we read it, so a read
% can catch a bad state: NaN values, or Time saved as a number (e.g. NaN)
% instead of a datetime, which used to throw "Cannot subtract a datetime
% array from a double array" and kill the experiment. Bad reads are
% retried a few times; if none is good, the last read is saved anyway with
% a warning so the experiment carries on (processing can fall back on a
% neighbouring trial's wind tunnel file, see get_nearby_wind_tunnel_file).
function wind_tunnel_save(case_name)
    max_tries = 20;
    retry_pause = 0.5; % s

    time_now = datetime;
    time_now.Format = 'yyyy-MM-dd HH-mm-ss';
    trial_name = strjoin(["data\wind tunnel data\" + case_name, "wind_tunnel", string(time_now)], "_");
    filepath = trial_name + ".mat";

    AFAM_Tunnel = [];
    good = false;
    for attempt = 1:max_tries
        try
            AFAM_Tunnel = load_afam_data;
            [good, AFAM_Tunnel, why] = check_afam(AFAM_Tunnel);
        catch ME
            why = ME.message;
        end
        if good
            break
        end
        disp("Bad AFAM read (" + why + "), trying again... (" + attempt + "/" + max_tries + ")")
        pause(retry_pause)
    end

    if isempty(AFAM_Tunnel)
        warning("wind_tunnel_save: could not read AFAM data for " + case_name + ...
            ", no wind tunnel file saved for this trial.");
        return
    end
    if ~good
        warning("wind_tunnel_save: saving AFAM data for " + case_name + ...
            " after " + max_tries + " bad reads (" + why + ").");
    else
        % Check that AFAM_tunnel updated recently enough
        if abs(AFAM_Tunnel.Time - datetime) > minutes(1)
            warning("AFAM_Tunnel data is outdated, please check the source.");
        end
    end

    save(filepath, 'AFAM_Tunnel');

    % Take a screenshot of the wind tunnel GUI so that we can also see the
    % history of the temperature and speed. This takes a screenshot of the
    % top right corner of the horizontal wind tunnel monitor.
    try
        screenshot(trial_name + ".jpg")
    catch ME
        warning("wind_tunnel_save: screenshot failed: " + ME.message);
    end
end

% Is this AFAM read usable? Converts a numeric Time (datenum) to datetime.
function [good, AFAM_Tunnel, why] = check_afam(AFAM_Tunnel)
    good = false;
    why = "";
    if ~isstruct(AFAM_Tunnel) || ~isfield(AFAM_Tunnel, "Time") || ~isfield(AFAM_Tunnel, "Speed")
        why = "missing Time or Speed";
        return
    end
    t = AFAM_Tunnel.Time;
    if isnumeric(t)
        if isscalar(t) && isfinite(t) && t > 7e5 % plausible datenum
            AFAM_Tunnel.Time = datetime(t, 'ConvertFrom', 'datenum');
        else
            why = "Time is " + class(t) + " " + mat2str(t);
            return
        end
    elseif ~isdatetime(t) || isempty(t) || any(isnat(t))
        why = "Time is not a valid datetime";
        return
    end
    if any(isnan(AFAM_Tunnel.Speed))
        why = "Speed is NaN";
        return
    end
    good = true;
end
