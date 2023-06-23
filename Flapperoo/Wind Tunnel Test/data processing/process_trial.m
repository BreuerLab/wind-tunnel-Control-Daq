clear
close all

% Ronan Gissler June 2023

% This file is used to plot the raw force transducer data from a
% single trial, giving a quick view of what that trial looked like.

[file,path] = uigetfile('*.csv');
if isequal(file,0)
   disp('User selected Cancel');
else
   disp(['User selected ', fullfile(path,file)]);
end

file = convertCharsToStrings(file);

frame_rate = 6000; % Hz
num_wingbeats = 180;

% Get case name from file name
case_name = erase(file, "_experiment_061723.csv");
case_name = strrep(case_name,'_',' ');

case_parts = strtrim(split(case_name));
wing_freq = -1;
AoA = -1;
for j=1:length(case_parts)
    if (contains(case_parts(j), "Hz"))
        wing_freq = str2double(erase(case_parts(j), "Hz"));
    elseif (contains(case_parts(j), "deg"))
        AoA = str2double(erase(case_parts(j), "deg"));
    end
end

% Get data from file
data = readmatrix(path + file);

force_data = data(:,1:7);
trigger_data = data(:,8);

trimmed_results = trim_data(force_data, trigger_data);

if (length(trimmed_results) == length(force_data))
    disp("Data was not trimmed.")
end

results_lab = coordinate_transformation(trimmed_results, AoA);

norm_data = non_dimensionalize_data(results_lab, wing_freq);