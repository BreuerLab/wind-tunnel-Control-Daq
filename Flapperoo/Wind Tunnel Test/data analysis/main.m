restoredefaultpath
% There are a lot of functions in the data processing folder,
% simply right click on the function you want to learn about to
% be brought to the file where it is defined. Of course this runs
% the risk of the same function name existing twice (an
% overloaded function).
addpath(genpath('../data processing'))

addpath UI_functions/

clear
close all force

% Sets up UI for comparing data over angles of attack
% monitor_num = 2;
% data_path = "F:\Final Force Data";
% a = compareAoAUI(monitor_num, data_path);
% a.dynamic_plotting();

% Sets up UI for comparing data over phase averaged wingbeat
% monitor_num = 1;
% data_path = "F:\Final Force Data/";
% b = compareWingbeatUI(monitor_num, data_path);
% b.dynamic_plotting();

% Sets up UI for comparing stability slope
monitor_num = 2;
data_path = "F:\Final Force Data";
c = compareStabilityUI(monitor_num, data_path);
c.dynamic_plotting();
% 
% monitor_num = 2;
% data_path = "F:\Final Force Data/";
% d = compareKinematicsUI(monitor_num, data_path);
% d.dynamic_plotting();
% 
% monitor_num = 2;
% data_path = "F:\Final Force Data/";
% e = compareKinematicsAoAUI(monitor_num, data_path);
% e.dynamic_plotting();
% 
% monitor_num = 1;
% data_path = "F:\Final Force Data/";
% f = compareKinematicsFreqUI(monitor_num, data_path);
% f.dynamic_plotting();

% Set up basic UI as demo for this kind of tool
% z = basicUI(2);
% z.dynamic_plotting();