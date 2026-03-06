clear
close all force

% Change current working directory to the directory where this file is
cd(fileparts(mfilename('fullpath')));
addpath(genpath('../../'))
addpath(genpath('.'))

% Set up basic UI as demo for this kind of tool
c = STB_UI(1);
c.dynamic_plotting();