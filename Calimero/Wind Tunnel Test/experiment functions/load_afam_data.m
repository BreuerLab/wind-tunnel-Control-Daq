function AFAM_Tunnel = load_afam_data
% Reads the AFAM wind tunnel state written by the AFAM PC. The file can be
% mid-write when read, so failed reads are retried a limited number of
% times (this used to retry immediately with no limit, which could hit
% MATLAB's recursion limit). Errors if it still
% can't be read after ~30 s; wind_tunnel_save catches that and carries on.
    max_tries = 150; % x 0.2 s pause
    for attempt = 1:max_tries
        try
            data = load("R:\ENG_Breuer_Shared\group\AFAM_state.mat");
            AFAM_Tunnel = data.AFAM_Tunnel;
            return
        catch ME
            pause(0.2)
        end
    end
    error("load_afam_data: could not read AFAM_state.mat after " + max_tries + ...
        " tries: " + ME.message)
end
