clear
close all force

% Change current working directory to the directory where this file is
cd(fileparts(mfilename('fullpath')));
addpath(genpath('../../'))
addpath(genpath('.'))

data_file_path = "Y:\Processed Results\";
% data_file_path = "/Volumes/ENG_Breuer_Shared/group/Ronan/STB Analysis/Processed Results/";

% GUI for plotting vector fields and wake topology
% c = STB_UI(1,data_file_path);
% c.dynamic_plotting();

% GUI for plotting phase averaged quantities
% a = compareWingbeatUI(2,data_file_path);
% a.dynamic_plotting();

% GUI for plotting time averaged quantities
root_path = "Y:\";
b = avgForceUI(2, root_path);
b.dynamic_plotting();