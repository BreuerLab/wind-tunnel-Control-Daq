restoredefaultpath
% There are a lot of functions in the data processing folder,
% simply right click on the function you want to learn about to
% be brought to the file where it is defined. Of course this runs
% the risk of the same function name existing twice (an
% overloaded function).
% addpath(genpath('../data processing'))

clear
clc
close all force

addpath(genpath('../../'))

DELIM = string(filesep);

% data_path = "F:\Calimero Data\Calimero 09_23_2025\"; % for comparing plot data across ladder, ascending, descending
% data_path = "F:\Calimero Data\Calimero 09_23_2025_ascending\";
if strcmp(DELIM, "\")
    data_path = uigetdir(".", "Select a 'plot data' folder") + DELIM;
    if isequal(data_path, 0)
        disp('User canceled folder selection.');
    else
        disp(['Selected folder: ', data_path]);
    end
else  % For Zachary's Mac to directly open file
    data_path = uigetdir("/Volumes/LRSResearch/ENG_Breuer_Shared/group/Zachary/Final Tests/Deleted Body Batch/Batch Processed/_PLOT_DATA/", "Select a 'plot data' folder") + DELIM;
    if isequal(data_path, 0)
        disp('User canceled folder selection.');
    else
        disp(['Selected folder: ', data_path]);
    end
end

% Sets up UI for comparing data over angles of attack
monitor_num = 1;

a = compareAoAUI(monitor_num, data_path);
a.dynamic_plotting();

% b = compareWingbeatUI(monitor_num, data_path);
% b.dynamic_plotting();