restoredefaultpath
% There are a lot of functions in the data processing folder,
% simply right click on the function you want to learn about to
% be brought to the file where it is defined. Of course this runs
% the risk of the same function name existing twice (an
% overloaded function).
% addpath(genpath('../data processing'))

addpath(genpath('../../Wind Tunnel Test'))
addpath(genpath('.'))
addpath(genpath('../'))

clear
close all force

% Sets up UI for comparing data over angles of attack
monitor_num = 1;
data_path = "F:\Calimero Data\Calimero_07_12_to_07_14_Tests";
a = compareAoAUI(monitor_num, data_path);
a.dynamic_plotting();