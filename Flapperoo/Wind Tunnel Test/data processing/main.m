clear
close all

% Ronan Gissler June 2023
folder_path = "C:\Users\rgissler\Desktop\Ronan Lab Documents\Stability Test Data\06_17_23\experiment data\";

[file,path] = uigetfile(folder_path + '*.csv');
if isequal(file,0)
   disp('User selected Cancel');
else
   disp(['User selected ', fullfile(path,file)]);
end

file = convertCharsToStrings(file);

process_trial(file, folder_path, true);