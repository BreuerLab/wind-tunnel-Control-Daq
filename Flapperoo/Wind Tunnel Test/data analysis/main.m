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
a = compareAoAUI(2);
a.dynamic_plotting();

% Sets up UI for comparing data over phase averaged wingbeat
% b = compareWingbeatUI(2);
% b.dynamic_plotting();

% Set up basic UI as demo for this kind of tool
% c = basicUI(2);
% c.dynamic_plotting();