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

vc7_filepath = "Y:\VC7 Data\";
% save_filepath = "R:\ENG_Breuer_Shared\rgissler\Calimero Flow Viz\Processed Results\";
save_filepath_local = "Y:\Processed Results\";

down_dist = [0, 1, 2]; % 0 - closest to FoV, 2 - furthest from FoV
% down_dist = [0]; % 0 - closest to FoV, 2 - furthest from FoV
bools.nondim = true; % non-dimensionalize data
bools.RPCA = true; % RPCA filtering of vector fields
bools.proc_vel = true; % false if just calculating secondary values

% If you want to make plots here, you can. However, it is NOT recommended.
% Intead, use main_analysis to produce plots easily in a GUI interface.
bools.PIV_plot = false;

% Plot bin histograms, speed, current, voltage (small overhead, quick)
bools.plot = false;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

case_names = get_case_names(vc7_filepath);
sel_case_names = [];
for i = 1:length(case_names)
    cur_name = case_names{i};
    % for phase averaged cases
    is_valid_base = ~contains(cur_name, "turbine") && ...
                contains(cur_name, "flexible") && ...
                ~contains(cur_name, "0Hz");

    % for time averaged cases
    % is_valid_base = ~contains(cur_name, "turbine") && ...
    %                 (~contains(cur_name, "flexible") || ...
    %                 contains(cur_name, "0Hz"));

    if is_valid_base
        is_match = false;
        
        if ismember(0, down_dist) && ~contains(cur_name, ["UP_one", "UP_two"])
            is_match = true;
        elseif ismember(1, down_dist) && contains(cur_name, "UP_one") && ~contains(cur_name, "UP_two")
            is_match = true;
        elseif ismember(2, down_dist) && ~contains(cur_name, "UP_one") && contains(cur_name, "UP_two")
            is_match = true;
        end
    
        % Append if any case matched
        if is_match
            sel_case_names = [sel_case_names, case_names(i)];
        end
    end
end

myFuncTimer = tic;
for i = 1:length(sel_case_names)
    PIV_case_name = sel_case_names(i);
    process_case(PIV_case_name, save_filepath_local, bools);
end
elapsed = toc(myFuncTimer);
fprintf('Batch took: %.4f seconds\n', elapsed);
return