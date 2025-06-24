
% Save wind tunnel struct variable so that we know the air properties
% for this trial
function wind_tunnel_save(case_name)
    time_now = datetime;
    time_now.Format = 'yyyy-MM-dd HH-mm-ss';
    trial_name = strjoin(["data\wind tunnel data\", case_name, "wind_tunnel", string(time_now)], "_");
    filepath = trial_name + ".mat";
    filepath_string = "'" + filepath + "'";
    evalin('base',"save(" + filepath_string + ", 'AFAM_Tunnel');");
    
    % Only keep wind tunnel file if values aren't NaN
    load(filepath)
    if isnan(AFAM_Tunnel.Speed)
        disp("Nan values in AFAM save, trying again...")
        delete(filepath)
        pause(0.2)
        wind_tunnel_save(case_name);
    end
    
    % Take a screenshot of the wind tunnel GUI so that we can also see the
    % history of the temperature and speed. This takes a screenshot of the
    % top right corner of the horizontal wind tunnel monitor.
    screenshot(trial_name + ".jpg")
end