restoredefaultpath
% For the future, it'd be best to move all the functions I'm
% using to a separate class where they can be called in such a
% way that it's clear where the function is originating from
% rather than this addpath statement which doesn't clarify which
% functions are local or from these other paths
addpath ..\'data processing'\general\
addpath ..\'data processing'\modeling\
addpath ..\'data processing'\'robot_parameters'

addpath UI_functions\

clear
close all force

% Sets up UI for comparing data over angles of attack
% a = compareAoAUI(1);
% a.dynamic_plotting();

% Sets up UI for comparing data over phase averaged wingbeat
b = compareWingbeatUI(2);
b.dynamic_plotting();

% Set up basic UI as demo for this kind of tool
% c = basicUI(2);
% c.dynamic_plotting();