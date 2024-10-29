restoredefaultpath
% There are a lot of functions in the data processing folder,
% simply right click on the function you want to learn about to
% be brought to the file where it is defined. Of course this runs
% the risk of the same function name existing twice (an
% overloaded function).
addpath(genpath('../data processing'))

addpath UI_functions\

clear
close all force

% Sets up UI for comparing data over angles of attack
monitor_num = 2;
data_path = "D:\Final Force Data";
a = compareAoAUI(monitor_num, data_path);
a.dynamic_plotting();

% Sets up UI for comparing data over phase averaged wingbeat
% monitor_num = 2;
% data_path = "D:\Final Force Data/";
% b = compareWingbeatUI(monitor_num, data_path);
% b.dynamic_plotting();

% Set up basic UI as demo for this kind of tool
% c = basicUI(2);
% c.dynamic_plotting();