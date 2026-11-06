function process_case(PIV_case_name, save_filepath_local, num_images, bools)

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

% Region of the wake kept for integral quantities (trim_vel_field),
% defined in default_trim_bounds.m
bounds = default_trim_bounds();

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

file_path = get_PIV_paths(PIV_case_name);

% Particle-based phase average (particle_process_case), after the binned
% one it takes its phase binning, grid and uncertainty mask from.
% bools.particle.only skips the binned processing (its files must exist).
particle = isfield(bools, 'particle') && bools.particle.run;
particle_only = particle && isfield(bools.particle, 'only') && bools.particle.only;

switch avg_type
    case 0
        if particle_only
            disp("Particle processing needs phase bins; skipping time-averaged case " + PIV_case_name)
            return
        end
        disp("Time Average: Loading file: " + file_path)
        S = time_avg_STB(file_path, U, L, save_filepath_local,...
            PIV_case_name, num_images, bools, bounds);
        
        if bools.PIV_plot
            time_avg_plots(S);
        end
        if particle
            disp("Particle processing skipped (time-averaged case)")
        end
    case 1
        if ~particle_only
            disp("Phase Average: Loading file: " + file_path)
            S = phase_avg_STB(file_path, U, L, save_filepath_local,...
                PIV_case_name, num_images, bools, bounds);

            if bools.PIV_plot
                error("Plotting phase averaged results not currently supported")
                phase_avg_plots(S);
            end
        end
        if particle
            particle_process_case(PIV_case_name, save_filepath_local, ...
                binned_version_name(bools), bools.particle);
        end
end

end