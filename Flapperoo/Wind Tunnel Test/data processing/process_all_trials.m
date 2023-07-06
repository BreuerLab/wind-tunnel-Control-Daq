clear
close all

% Ronan Gissler June 2023
path = "C:\Users\rgissler\Desktop\Ronan Lab Documents\Stability Test Data\06_17_23\experiment data\";

% Get a list of all files in the folder with the desired file name pattern.
filePattern = fullfile(path, '*.csv'); % Change to whatever pattern you need.
theFiles = dir(filePattern);

cases = "";

for k = 1 : length(theFiles)
    baseFileName = theFiles(k).name;

    process_trial(baseFileName, path, false);

    percent_complete = round((k / length(theFiles)) * 100, 2);
    disp(percent_complete + "% complete")
end