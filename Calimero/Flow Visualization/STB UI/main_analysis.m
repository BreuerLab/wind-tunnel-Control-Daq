clear
close all force

% Change current working directory to the directory where this file is
cd(fileparts(mfilename('fullpath')));
addpath(genpath('../../'))
addpath(genpath('.'))

data_file_path = "Y:\Processed Results\";
% data_file_path = "/Volumes/ENG_Breuer_Shared/group/Ronan/STB Analysis/Processed Results/";

% Set up basic UI as demo for this kind of tool
% c = STB_UI(1,data_file_path);
% c.dynamic_plotting();

% Set up basic UI as demo for this kind of tool
a = compareWingbeatUI(1,data_file_path);
a.dynamic_plotting();

% root_path = "Y:\";
% b = avgForceUI(1, root_path);
% b.dynamic_plotting();