function process_case(PIV_case_name, save_filepath_local, bools)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% ------------------------ Dependent parameters --------------------------
if contains(PIV_case_name,"turbine")
    bools.turbine = true;
else
    bools.turbine = false;
end

% characteristic windspeed (freestream) and characteristic length
if bools.turbine
    U = 6;
    L = 0.07; % temp value, replace with diameter of turbine
else
    U = 4;
    L = 0.07; % guess of mean aerodynamic chord
end

if  ~contains(PIV_case_name, "turbine") && (contains(PIV_case_name, "0Hz")...
        || ~contains(PIV_case_name, "Hz"))
    avg_type = 0; % 0 - time average
else
    avg_type = 1; % 1 - phase average
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

file_path = get_PIV_paths(PIV_case_name);

switch avg_type
    case 0
        disp("Time Average: Loading file: " + file_path)
        S = time_avg_STB(file_path, U, L, save_filepath_local,...
            PIV_case_name, bools);
        
        if bools.PIV_plot
            time_avg_plots(S);
        end
    case 1
        disp("Phase Average: Loading file: " + file_path)
        S = phase_avg_STB(file_path, U, L, save_filepath_local,...
            PIV_case_name, bools);

        if bools.PIV_plot
            error("Plotting phase averaged results not currently supported")
            phase_avg_plots(S);
        end
end

end