clear
close all

% Change current working directory to the directory where this file is
cd(fileparts(mfilename('fullpath'))); 
addpath(genpath('../../'))
addpath(genpath('.'))
addpath(genpath('C:\Users\rgissler\Documents\MATLAB')) % readimx path

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% ----------------------- Parameter Selection ------------------------
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Cases to process, using the names in get_PIV_paths.m
% (call "  get_PIV_paths()  " with no input to list them all)
% sel_case_names = ["x3_wings_20deg_2Hz", "x3_wings_20deg_4Hz", ...
%                   "x3_wings_20deg_6Hz", "x3_wings_20deg_8Hz"];

% Alternatively, select cases by filter. Leave a filter empty to accept
% any value. Uncomment the line below the filters to use them.
positions = ["x2"];        % "x1"-"x5", "MPS", "UP_one", "UP_two", "" = old 0.9 m cases (no prefix)
amps = [];               % flapping amplitude (deg)
freqs = [];         % wingbeat frequency (Hz), 0 = gliding
sel_case_names = select_cases(get_PIV_paths(), positions, amps, freqs);
% All cases found (every listed case and every September\<pos>\<case>
% folder): set the three filters above to [] or uncomment this line
% sel_case_names = get_PIV_paths();

% Keep only flapping or only static cases from the selection above
% (whichever way it was made):
%   "all"      - no change
%   "flapping" - phase-averaged cases (nonzero wingbeat frequency, and the
%                turbine cases)
%   "static"   - time-averaged cases: 0 Hz (gliding) and cases without a
%                frequency (ring, body, freestream, NACA)
% Same rule process_case uses to pick a time or phase average. Static
% cases without an amplitude or frequency (ring, freestream, ...) only
% pass empty amps / freqs filters above, e.g. for every static case:
% positions = []; amps = []; freqs = []; motion = "static";
motion = "flapping";

% Number of images per case: "auto" counts the .vc7 files in each case's
% data folder (get_PIV_paths) and uses that; a number uses it for every
% case. Cases with no .vc7 files are skipped and logged.
num_images = "auto";
% num_images = 3000;

% true: skip cases that already have a processed file (with the version,
% HR and RPCA settings below) in save_filepath_local or its phase_avg\ /
% time_avg\ subfolders
skip_processed = true;

% save_filepath = "R:\ENG_Breuer_Shared\rgissler\Calimero Flow Viz\Processed Results\";
save_filepath_local = "C:\Users\rgissler\Documents\STB Processed Results\";

bools.nondim = true; % non-dimensionalize data
bools.RPCA = false; % RPCA filtering of vector fields
bools.Q_inst = false; % per-frame Q averaged over each bin, plus its std (Q*_inst_avg, Q*_inst_std), slow
bools.vort_uavg = false; % vorticity of the averaged velocity (vort*_uavg)
bools.div_std = true; % frame-to-frame std of the velocity divergence: per bin (div_phase_std), or over all frames for time averages (std_div); quick
bools.num_workers = 8; % parallel workers for phase bins / time-avg frame chunks (0 = serial); lower if out of memory
bools.frames_per_chunk = 20; % time averages: frames loaded and processed per call on each worker; lower if out of memory
bools.compress_save = true; % true = compressed -v7.3 .mat (smaller, slower to save); compress_STB_files for files already saved
bools.proc_vel = true; % false if just calculating secondary values
% Processed files: <case>[_<version>]_shared.mat (DAQ, binning, grid, frames)
% plus <case>[_<version>]_<method>_fields.mat and _<method>_integral.mat
% per method (bin, bin_hr, particle_pool_hr20, ...) in Processed Results\phase_avg\.
% true: also write the old combined files (<case>[_<version>]_phase_avg.mat
% and _phase_avg_integral.mat). Nothing reads them any more (the GUIs use
% the files above), so leave false unless older scripts need them.
bools.legacy_files = false;

% Range of phase-bin counts to search. findBestNumBins2 picks the count
% in this range (and the bin offset) with the smallest phase spread per
% bin; it was choosing ~193 in 180-210. Fewer bins = more frames per bin
% (less noise) but coarser phase resolution. [n n] forces n bins.
bools.bin_range = [180 200];

% Version name added to the saved file names, e.g. "coarse" saves
% x3_wings_20deg_6Hz_coarse_phase_avg.mat (and _integral.mat); phaseAvg_UI
% lists it under that name in its version dropdown. "" = default (no
% suffix). Phase averages only; avoid "deg" and "Hz" in the name.
bools.version = "";

% Harmonic regression instead of bin averaging. Each point's time series
% is fitted over ALL frames at their actual phases with a Fourier series
% of num_harmonics wingbeat harmonics, then evaluated at the bin centres,
% so the saved fields have the same shape as the bin averages and the UIs
% and secondary values work unchanged. Removes the phase spread within
% bins and filters noise above num_harmonics x wingbeat frequency. std,
% Reynolds stresses and Q_inst are still computed per bin. Saved with
% "_hr" added to the version name (e.g. coarse_hr), so it doesn't
% overwrite the bin-averaged files. See harmonic_regression_STB.m.
bools.harmonic_reg = false;
bools.num_harmonics = 20; % 2*10+1 = 21 coefficients per point and field
bools.hr_save_coef = false; % save coefficients (to evaluate fit / exact d/dt at any phase); large files

% Particle-based phase average (particle tracks\particle_process_case):
% velocity and vorticity fitted directly to the STB particle tracks (local
% polynomial through the slab depth, so d/dx across the thin slab is
% resolved much better than by binning), then the same integral quantities
% as for the binned data, saved as its own version for phaseAvg_UI /
% flowField_UI (e.g. particle_pool_hr20). Runs after the binned
% phase average of each case, which supplies the phase binning, grid,
% uncertainty mask and DAQ data. Time-averaged cases are skipped.
% All settings and their meaning: particle_default_opts.m
bools.particle = particle_default_opts();
bools.particle.run  = true;   % true: add the particle processing
bools.particle.only = false;   % true: only the particle processing (binned files must exist)
bools.particle.reuse_fit = false;  % true: reuse saved particle fits, only redo the integrals
% bools.particle.run_tag      = "o3";     % tag non-default fit settings in the file names
% bools.particle.fit.depthOrder = 5;
% bools.particle.hr_harmonics = 20;     % harmonic regression across bins, 0 = off
bools.particle.cache = false;

% If you want to make plots here, you can. However, it is NOT recommended.
% Intead, use main_analysis to produce plots easily in a GUI interface.
bools.PIV_plot = false;

% Plot bin histograms, speed, current, voltage (small overhead, quick)
bools.plot = false;

% true: keep going if a case errors and report it at the end
continue_on_error = true;

% true: after each case, shut down the parallel pool (its workers keep
% their memory) and close the particle sets Python holds, so that memory
% is freed before the next case. The pool restarts on its own (~30 s per
% case); Python keeps running, since it couldn't be restarted mid-batch.
% Without it, cases after the first can run out of memory.
reset_between_cases = true;

% Every run is appended to this log: the settings, each case's name, data
% folder, number of .vc7 files / images used, status and time, so it can
% be reviewed later which cases were processed and how
log_file = fullfile(save_filepath_local, "processing_log.txt");

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

sel_case_names = string(sel_case_names);
switch motion
    case "all"
    case "flapping"
        sel_case_names = sel_case_names(~arrayfun(@is_static_case, sel_case_names));
    case "static"
        sel_case_names = sel_case_names(arrayfun(@is_static_case, sel_case_names));
    otherwise
        error('motion must be "all", "flapping" or "static", not "%s"', motion)
end
if isempty(sel_case_names)
    error('No cases selected (motion = "%s")', motion)
end

% Check every name before starting, so a typo doesn't stop the batch
% hours in
all_case_names = get_PIV_paths();
unknown = sel_case_names(~ismember(sel_case_names, all_case_names));
if ~isempty(unknown)
    error("Case(s) not in get_PIV_paths.m: %s", strjoin(unknown, ", "))
end

% ----- Find each case's data folder and number of .vc7 files -----
cases = scan_cases(sel_case_names, num_images, save_filepath_local, bools, skip_processed);
run_mask = cases.status == "queued";
num_cases = sum(run_mask);

log_line(log_file, "")
log_line(log_file, repmat('=', 1, 78))
log_line(log_file, "Batch started " + string(datetime("now", "Format", "yyyy-MM-dd HH:mm:ss")) + ...
    " on " + string(getenv("COMPUTERNAME")) + " (" + string(getenv("USERNAME")) + ")")
log_line(log_file, "Code version: " + code_version())
log_line(log_file, "Save folder: " + save_filepath_local)
log_line(log_file, "motion: " + motion)
log_line(log_file, "num_images: " + string(num_images) + ...
    ", skip_processed: " + string(skip_processed) + ", continue_on_error: " + string(continue_on_error) + ...
    ", reset_between_cases: " + string(reset_between_cases))
log_line(log_file, "Settings: " + bools_to_text(bools))
log_line(log_file, sprintf("%d case(s) selected, %d to process:", numel(cases.name), num_cases))
for k = 1:numel(cases.name)
    log_line(log_file, sprintf("  %-28s %6s vc7  %-9s %s", cases.name(k), ...
        string(cases.num_vc7(k)), cases.status(k), cases.folder(k)))
end

if num_cases == 0
    log_line(log_file, "Nothing to process")
    error("No cases to process (see %s)", log_file)
end
disp("Processing " + num_cases + " case(s): " + strjoin(cases.name(run_mask), ", "))
disp("Log: " + log_file)

failed = strings(0);
myFuncTimer = tic;
run_idx = find(run_mask);
for i = 1:num_cases
    k = run_idx(i);
    PIV_case_name = cases.name(k);
    case_images = cases.num_images(k);
    fprintf('\n===== [%d/%d] %s (%d images) =====\n', i, num_cases, PIV_case_name, case_images);
    caseTimer = tic;
    status = "done";
    message = "";
    if continue_on_error
        try
            process_case(PIV_case_name, save_filepath_local, case_images, bools);
        catch err
            failed(end+1) = PIV_case_name; %#ok<SAGROW>
            status = "FAILED";
            message = string(err.message);
            fprintf(2, 'FAILED %s:\n%s\n', PIV_case_name, getReport(err));
        end
    else
        process_case(PIV_case_name, save_filepath_local, case_images, bools);
    end
    minutes = toc(caseTimer)/60;
    fprintf('%s took %.1f minutes\n', PIV_case_name, minutes);
    % written as each case finishes, so the log is complete up to a crash
    log_line(log_file, sprintf("[%d/%d] %s  %s  %d images (%d vc7)  %s average  %.1f min  %s", ...
        i, num_cases, string(datetime("now", "Format", "HH:mm:ss")), PIV_case_name, ...
        case_images, cases.num_vc7(k), cases.avg_type(k), minutes, status))
    if strlength(message) > 0
        log_line(log_file, "      error: " + replace(message, newline, " "))
    end
    close all
    if reset_between_cases && i < num_cases
        release_memory()
    end
end
elapsed = toc(myFuncTimer);

fprintf('\nBatch took: %.1f minutes\n', elapsed/60);
if isempty(failed)
    disp("All " + num_cases + " case(s) processed")
    summary = sprintf("Batch finished in %.1f min: all %d case(s) processed", elapsed/60, num_cases);
else
    disp("Failed (" + length(failed) + "): " + strjoin(failed, ", "))
    summary = sprintf("Batch finished in %.1f min: %d of %d failed (%s)", elapsed/60, ...
        numel(failed), num_cases, strjoin(failed, ", "));
end
log_line(log_file, summary)
return

% Select case names matching the given position(s), amplitude(s) and
% frequency(ies). Names follow <position>_<model>_<amp>deg_<freq>Hz,
% e.g. x3_wings_20deg_6Hz or UP_one_flexible_10deg_2Hz. Names without an
% amplitude/frequency (e.g. x3_ring) only pass an empty amp/freq filter.
function names = select_cases(case_names, positions, amps, freqs)
    case_names = string(case_names);
    keep = true(size(case_names));

    for i = 1:length(case_names)
        name = case_names(i);

        if ~isempty(positions)
            pos = get_downstream_prefix(name, true); % e.g. "x3_", "UP_one_", ""
            keep(i) = keep(i) && ismember(erase(pos, "_"), erase(string(positions), "_"));
        end

        amp = parse_number(name, '_(\d+)deg');
        if ~isempty(amps)
            keep(i) = keep(i) && ~isnan(amp) && ismember(amp, amps);
        end

        freq = parse_number(name, '_(\d+)Hz');
        if ~isempty(freqs)
            keep(i) = keep(i) && ~isnan(freq) && ismember(freq, freqs);
        end
    end

    names = case_names(keep);
end

% Data folder, number of .vc7 files and images to use for each case, and
% whether it will be processed ("queued") or why not
function cases = scan_cases(names, num_images, save_folder, bools, skip_processed)
    n = numel(names);
    cases.name = names(:);
    cases.folder = strings(n, 1);
    cases.num_vc7 = zeros(n, 1);
    cases.num_images = zeros(n, 1);
    cases.avg_type = strings(n, 1);
    cases.status = repmat("queued", n, 1);

    % saved name suffix, as phase_avg_STB builds it
    version = "";
    if isfield(bools, 'version') && strlength(string(bools.version)) > 0
        version = "_" + string(bools.version);
    end
    if isfield(bools, 'harmonic_reg') && bools.harmonic_reg
        if strlength(version) > 0
            version = version + "_hr";
        else
            version = "_hr";
        end
    end
    if isfield(bools, 'RPCA') && bools.RPCA
        version = version + "_RPCA";
    end

    % particle processing only: static cases have nothing to do, and
    % skip_processed looks for the particle integral file
    particle_only = isfield(bools, 'particle') && bools.particle.run && bools.particle.only;
    base_version = "";
    if isfield(bools, 'version'), base_version = string(bools.version); end

    for k = 1:n
        name = cases.name(k);
        if is_static_case(name)
            cases.avg_type(k) = "time"; % same rule as process_case
        else
            cases.avg_type(k) = "phase";
        end
        if particle_only && cases.avg_type(k) == "time"
            cases.status(k) = "static";   % no phase bins for the particle steps
            continue
        end

        try
            FR = get_case_frames(name);           % combined folder or batch folders
            if FR.layout == "folder"
                cases.folder(k) = FR.folders(1);
            else
                cases.folder(k) = FR.case_folder + sprintf(" (%d batches)", numel(FR.folders));
            end
            cases.num_vc7(k) = numel(FR.vc7);
        catch err
            if any(err.identifier == ["get_case_frames:noVc7", "get_case_frames:count", ...
                                      "get_case_frames:gaps", "get_case_frames:duplicates"])
                cases.status(k) = "bad frames";
                fprintf(2, '%s: %s\n', name, err.message);
            else
                cases.status(k) = "no folder";
            end
            continue
        end
        if cases.num_vc7(k) == 0
            cases.status(k) = "no vc7";
            continue
        end

        if isstring(num_images) || ischar(num_images)
            cases.num_images(k) = cases.num_vc7(k); % "auto"
        else
            cases.num_images(k) = num_images;
            if num_images > cases.num_vc7(k)
                cases.status(k) = "too few";
                continue
            end
        end

        % new layout (stb_file_paths): the method's integral file is written last
        if skip_processed && cases.avg_type(k) == "phase"
            if particle_only
                Pn = stb_file_paths(save_folder, name, base_version, particle_method_name(bools.particle));
            else
                Pn = stb_file_paths(save_folder, name, base_version, binned_method_name(bools));
            end
            done = isfile(Pn.integral);
            % redoing only the integrals: done once the integral file has
            % the uncertainty bands (hr_band, particle_integrals_case)
            if done && particle_only && isfield(bools.particle, 'reuse_fit') && bools.particle.reuse_fit
                done = ismember('hr_band', who('-file', char(Pn.integral)));
            end
            if done
                cases.status(k) = "skipped";
                continue
            end
        end
        if skip_processed && particle_only
            % (legacy names are not checked for particle-only runs)
        elseif skip_processed
            % new files are saved in save_folder itself; processed ones are
            % kept in its time_avg\ / phase_avg\ (and phase_avg\RPCA\)
            if cases.avg_type(k) == "time"
                file = name + "_time_avg.mat";
                dirs = [string(save_folder), fullfile(save_folder, "time_avg")];
            else
                file = name + version + "_phase_avg.mat";
                dirs = [string(save_folder), fullfile(save_folder, "phase_avg"), ...
                    fullfile(save_folder, "phase_avg", "RPCA")];
            end
            for d = dirs
                if isfile(fullfile(d, file))
                    cases.status(k) = "skipped";
                end
            end
        end
    end
end

% Free the memory held between cases: the parallel pool's workers keep
% their memory after a parfor, and Python keeps the particle data it read
function release_memory()
    pool = gcp('nocreate');
    if ~isempty(pool)
        delete(pool);
    end
    stbPyRelease();   % close the particle sets; Python itself keeps running
end

% True for cases that are time averaged (static: 0 Hz, or no frequency
% such as ring, body, freestream), false for phase-averaged ones
% (flapping, turbine). Same rule as process_case.
function tf = is_static_case(name)
    tf = ~contains(name, "turbine") && (contains(name, "0Hz") || ~contains(name, "Hz"));
end

% Append one line to the processing log
function log_line(log_file, txt)
    fid = fopen(log_file, "a");
    if fid < 0
        warning("Could not write to the processing log %s", log_file)
        return
    end
    fprintf(fid, "%s\n", txt);
    fclose(fid);
end

% The bools settings as "name=value" pairs
function txt = bools_to_text(bools)
    names = fieldnames(bools);
    parts = strings(numel(names), 1);
    for k = 1:numel(names)
        v = bools.(names{k});
        if isstruct(v) && isscalar(v)
            parts(k) = names{k} + ".{" + bools_to_text(v) + "}";   % e.g. particle settings
            continue
        end
        if isstring(v) || ischar(v)
            v = '"' + string(v) + '"'; % quoted, e.g. version="coarse"
        elseif isnumeric(v) || islogical(v)
            v = string(mat2str(v));
        else
            v = "<" + class(v) + ">";
        end
        parts(k) = names{k} + "=" + v;
    end
    txt = strjoin(parts, ", ");
end

% Git commit of the code being run (with "+changes" if there are
% uncommitted edits), or "unknown" if git isn't available
function v = code_version()
    v = "unknown";
    repo = fileparts(mfilename('fullpath'));
    [s1, hash] = system(sprintf('git -C "%s" rev-parse --short HEAD', repo));
    if s1 ~= 0
        return
    end
    v = strtrim(string(hash));
    [s2, changes] = system(sprintf('git -C "%s" status --porcelain', repo));
    if s2 == 0 && strlength(strtrim(string(changes))) > 0
        v = v + " +changes";
    end
end

% Number captured by the pattern's token, NaN if the name doesn't match
% (e.g. no amplitude in "x3_ring")
function val = parse_number(name, pattern)
    tok = regexp(char(name), pattern, 'tokens', 'once');
    if isempty(tok)
        val = NaN;
    else
        val = str2double(tok{1});
    end
end
