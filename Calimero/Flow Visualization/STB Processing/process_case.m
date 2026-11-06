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

% The case's .vc7 frames in recording order: one combined binning folder,
% or the binning folders of the batches the trial was processed in
% (get_case_frames). loadpiv reads either.
FR = get_case_frames(PIV_case_name);
if FR.layout == "folder"
    file_path = FR.folders(1);
else
    file_path = FR.vc7;
end
if num_images > numel(FR.vc7)
    error('process_case:numImages', '%s has %d frames, fewer than num_images = %d.', ...
          PIV_case_name, numel(FR.vc7), num_images);
end

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
        disp("Time Average: loading " + describe_frames(FR))
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
            disp("Phase Average: loading " + describe_frames(FR))
            S = phase_avg_STB(file_path, U, L, save_filepath_local,...
                PIV_case_name, num_images, bools, bounds);

            if bools.PIV_plot
                error("Plotting phase averaged results not currently supported")
                phase_avg_plots(S);
            end
        end
        if particle
            if ~particle_only
                bools.particle.binned_method = binned_method_name(bools);   % uncertainty mask from this run
            end
            if isfield(bools, 'legacy_files'), bools.particle.legacy_files = bools.legacy_files; end
            version = "";
            if isfield(bools, 'version'), version = string(bools.version); end
            particle_process_case(PIV_case_name, save_filepath_local, version, bools.particle);
        end
end

end

% -------------------------------------------------------------------------
% One line per binning folder: first and last file and whether the files
% in between are numbered consecutively, instead of every file name
function txt = describe_frames(FR)
    lines = sprintf("%d frames", numel(FR.vc7));
    for k = 1:numel(FR.folders)
        if numel(FR.folders) == 1
            f = FR.vc7;
        else
            f = FR.vc7(startsWith(FR.vc7, FR.folders(k) + filesep, 'IgnoreCase', true));
            if isempty(f), continue; end
        end
        [~, n1, e1] = fileparts(f(1));  [~, nN, eN] = fileparts(f(end));
        num = str2double(regexp(cellstr(f), '(\d+)(?=\.vc7$)', 'match', 'once'));
        if all(isfinite(num)) && all(diff(num) == 1)
            order = "numbered consecutively";
        else
            order = "numbering not consecutive";
        end
        lines(end+1) = sprintf("  %s: %s%s ... %s%s (%d files, %s)", FR.folders(k), ...
                               n1, e1, nN, eN, numel(f), order); %#ok<AGROW>
    end
    txt = strjoin(lines, newline);
end

