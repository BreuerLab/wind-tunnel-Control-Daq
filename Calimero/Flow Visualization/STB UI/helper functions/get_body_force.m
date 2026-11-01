function body_force = get_body_force(path, type, amp, freq, idx, var_name_F)
    % Body (no wings) load cell signal to subtract for Force Body Sub, for
    % a wing case's type, amplitude and frequency. Uses the body case at
    % the same amplitude. Only if there is no body data at all for that
    % amplitude (old flapper: no 30 deg body cases) does it fall back to
    % the 20 deg body case. The latest repeat is used (see get_force).
    body_type = get_downstream_prefix(type) + "body";
    try
        body_force = get_force(path, body_type, amp, freq, idx, var_name_F);
    catch ME
        if ME.identifier == "get_force:folderNotFound" && str2double(string(amp)) == 30
            disp("No 30 deg body data, subtracting the 20 deg body case instead")
            body_force = get_force(path, body_type, 20, freq, idx, var_name_F);
        else
            rethrow(ME)
        end
    end
end
