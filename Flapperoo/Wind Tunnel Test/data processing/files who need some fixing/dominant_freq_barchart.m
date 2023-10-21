% Ronan Gissler June 2023
clear
close all

data_path = "../processed data/";

% Get a list of all files in the folder with the desired file name pattern.
filePattern = fullfile(data_path, '*.mat'); % Change to whatever pattern you need.
theFiles = dir(filePattern);
theFiles(contains({theFiles(:).name}, '0Hz')) = [];

% uncomment these lines to look at just the inertial trials
% theFiles(contains({theFiles(:).name}, 'body')) = [];
% theFiles(contains({theFiles(:).name}, 'mylar')) = [];

wing_freq_matches = zeros(1,6);
for i = 1:length(theFiles)
    baseFileName = theFiles(i).name;
    
    case_name = erase(baseFileName, ".mat");
    case_parts = strtrim(split(case_name));
    wing_freq = -1;
    for j=1:length(case_parts)
        if (contains(case_parts(j), "Hz"))
            wing_freq = str2double(erase(case_parts(j), "Hz"));
        end
    end

    load(data_path + baseFileName);
    dominant_freq_mult(i,:) = dominant_freq / wing_freq;

    percent_complete = round((i / length(theFiles)) * 100, 2);
    disp(percent_complete + "% complete")
end

% Open a new figure.
f = figure;
f.Position = [200 50 900 560];
tcl = tiledlayout(2,3);

% Create three subplots to show the force time histories. 
nexttile(tcl)
[B,BG,BP] = groupcounts(dominant_freq_mult(:,1));
% BG(BP < 2) = [];
% BP(BP < 2) = [];
bar(BG, BP);
xlim([0 20]);
ylim([0 90]);
title(["F_x (streamwise)"]);
xlabel(["Frequency in Force Data" "Normalized by Wingbeat Frequency"]);
ylabel("Percent Occurence Over all Flapping Trials");

nexttile(tcl)
[B,BG,BP] = groupcounts(dominant_freq_mult(:,2));
bar(BG, BP);
xlim([0 20]);
ylim([0 90]);
title(["F_y (transverse)"]);
xlabel(["Frequency in Force Data" "Normalized by Wingbeat Frequency"]);
ylabel("Percent Occurence Over all Flapping Trials");

nexttile(tcl)
[B,BG,BP] = groupcounts(dominant_freq_mult(:,3));
bar(BG, BP);
xlim([0 20]);
ylim([0 90]);
title(["F_z (vertical)"]);
xlabel(["Frequency in Force Data" "Normalized by Wingbeat Frequency"]);
ylabel("Percent Occurence Over all Flapping Trials");

% Create three subplots to show the moment time histories.
nexttile(tcl)
[B,BG,BP] = groupcounts(dominant_freq_mult(:,4));
bar(BG, BP);
xlim([0 20]);
ylim([0 90]);
title(["M_x (roll)"]);
xlabel(["Frequency in Force Data" "Normalized by Wingbeat Frequency"]);
ylabel("Percent Occurence Over all Flapping Trials");

nexttile(tcl)
[B,BG,BP] = groupcounts(dominant_freq_mult(:,5));
bar(BG, BP);
xlim([0 20]);
ylim([0 90]);
title(["M_y (pitch)"]);
xlabel(["Frequency in Force Data" "Normalized by Wingbeat Frequency"]);
ylabel("Percent Occurence Over all Flapping Trials");

nexttile(tcl)
[B,BG,BP] = groupcounts(dominant_freq_mult(:,6));
bar(BG, BP);
xlim([0 20]);
ylim([0 90]);
title(["M_z (yaw)"]);
xlabel(["Frequency in Force Data" "Normalized by Wingbeat Frequency"]);
ylabel("Percent Occurence Over all Flapping Trials");

% Label the whole figure.
sgtitle("Dominant Force Reading Frequencies for Flapping Experiments n = " + length(dominant_freq_mult(:,1)));