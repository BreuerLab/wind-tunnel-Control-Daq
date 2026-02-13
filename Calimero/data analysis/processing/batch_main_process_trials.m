clear
close all

cd(fileparts(mfilename('fullpath')));
addpath(genpath('../../'))

DELIM = string(filesep);

h = helpdlg("Please select the batch folder with the trial folders you'd like to process.");
uiwait(h);     % ensure the user reads it before continuing

% Open a file selection dialog and get the file path
if strcmp(DELIM, "\")
    data_path = uigetdir(".", "Select the batch folder") + DELIM;
    if isequal(data_path, 0)
        disp('User canceled folder selection.');
    else
        disp(['Selected folder: ', data_path]);
    end
else  % For Zachary's Mac to directly open file
    data_path = uigetdir("/Users/zjrosoff/Documents/GitHub/wind-tunnel-Control-Daq/Calimero/data analysis/processing", "Select the batch folder") + DELIM;
    if isequal(data_path, 0)
        disp('User canceled folder selection.');
    else
        disp(['Selected folder: ', data_path]);
    end
end

batch_cases = dir(data_path);
   
for i=4:length(batch_cases)
     
    path = data_path + string(batch_cases(i).name) + DELIM;
    batch_process_all_trials(path)
end