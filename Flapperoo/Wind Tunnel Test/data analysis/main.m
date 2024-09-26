restoredefaultpath
addpath ..\'data processing'\general\
addpath UI_functions\

clear
close all force

% Sets up UI for comparing data over angles of attack
a = compareAoAUI();
a.dynamic_plotting();

% Sets up UI for comparing data over phase averaged wingbeat
b = compareWingbeatUI();
b.dynamic_plotting();