function wind_tunnel_save(case_name)
% Save wind tunnel struct variable so that we know the air properties
% for this trial
trial_name = strjoin([case_name, "wind_tunnel", datestr(now, "mmddyy")], "_");
trial_file_name = "data\wind tunnel data\" + trial_name;
struct_file_name = trial_file_name + ".mat";
struct_file_name = "'" + struct_file_name + "'";
evalin('base',"save(" + struct_file_name + ", 'AFAM_Tunnel');");

% Take a screenshot of the wind tunnel GUI so that we can also see the
% history of the temperature and speed. This takes a screenshot of the
% top right corner of the horizontal wind tunnel monitor.
screenshot(trial_file_name + ".jpg")
end