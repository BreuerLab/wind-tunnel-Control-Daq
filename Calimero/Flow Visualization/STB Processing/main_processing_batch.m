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
positions = ["x3"];        % "x1"-"x5", "MPS", "UP_one", "UP_two", "" = old 0.9 m cases (no prefix)
amps = [30];               % flapping amplitude (deg)
freqs = [2 4 6];         % wingbeat frequency (Hz), 0 = gliding
sel_case_names = select_cases(get_PIV_paths(), positions, amps, freqs);

% num_images = 1200;
num_images = 3000;

% save_filepath = "R:\ENG_Breuer_Shared\rgissler\Calimero Flow Viz\Processed Results\";
save_filepath_local = "F:\Processed Results\";

bools.nondim = true; % non-dimensionalize data
bools.RPCA = false; % RPCA filtering of vector fields
bools.Q_inst = false; % per-frame Q averaged over each bin, plus its std (Q*_inst_avg, Q*_inst_std), slow
bools.vort_uavg = false; % vorticity of the averaged velocity (vort*_uavg)
bools.num_workers = 8; % parallel workers for phase bins (0 = serial); lower if out of memory
bools.compress_save = false; % true = MATLAB's compressed .mat (smaller, much slower to save)
bools.proc_vel = true; % false if just calculating secondary values

% Range of phase-bin counts to search. findBestNumBins2 picks the count
% in this range (and the bin offset) with the smallest phase spread per
% bin; it was choosing ~193 in 180-210. Fewer bins = more frames per bin
% (less noise) but coarser phase resolution. [n n] forces n bins.
bools.bin_range = [180 210];

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
bools.num_harmonics = 10; % 2*10+1 = 21 coefficients per point and field
bools.hr_save_coef = false; % save coefficients (to evaluate fit / exact d/dt at any phase); large files

% If you want to make plots here, you can. However, it is NOT recommended.
% Intead, use main_analysis to produce plots easily in a GUI interface.
bools.PIV_plot = false;

% Plot bin histograms, speed, current, voltage (small overhead, quick)
bools.plot = false;

% true: keep going if a case errors and report it at the end
continue_on_error = true;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

sel_case_names = string(sel_case_names);
num_cases = length(sel_case_names);
if num_cases == 0
    error("No cases selected")
end

% Check every name before starting, so a typo doesn't stop the batch
% hours in
all_case_names = get_PIV_paths();
unknown = sel_case_names(~ismember(sel_case_names, all_case_names));
if ~isempty(unknown)
    error("Case(s) not in get_PIV_paths.m: %s", strjoin(unknown, ", "))
end

disp("Processing " + num_cases + " case(s): " + strjoin(sel_case_names, ", "))

failed = strings(0);
myFuncTimer = tic;
for i = 1:num_cases
    PIV_case_name = sel_case_names(i);
    fprintf('\n===== [%d/%d] %s =====\n', i, num_cases, PIV_case_name);
    caseTimer = tic;
    if continue_on_error
        try
            process_case(PIV_case_name, save_filepath_local, num_images, bools);
        catch err
            failed(end+1) = PIV_case_name;
            fprintf(2, 'FAILED %s:\n%s\n', PIV_case_name, getReport(err));
        end
    else
        process_case(PIV_case_name, save_filepath_local, num_images, bools);
    end
    fprintf('%s took %.1f minutes\n', PIV_case_name, toc(caseTimer)/60);
    close all
end
elapsed = toc(myFuncTimer);

fprintf('\nBatch took: %.1f minutes\n', elapsed/60);
if isempty(failed)
    disp("All " + num_cases + " case(s) processed")
else
    disp("Failed (" + length(failed) + "): " + strjoin(failed, ", "))
end
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
