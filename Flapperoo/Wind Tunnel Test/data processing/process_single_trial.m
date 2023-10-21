% Ronan Gissler June 2023
clear
close all
addpath 'process trial'
addpath 'process trial/functions'
addpath 'plotting'

path = "C:\Users\rgissler\Desktop\Ronan Lab Documents\Stability Test Data\10_12_2023 New Wings New Body\experiment data\";

file = convertCharsToStrings(uigetfile(path + "*.csv"));
if isequal(file,0)
   disp('User selected Cancel');
else
   disp("User selected " + path + file);
end

process_trial(file, path);