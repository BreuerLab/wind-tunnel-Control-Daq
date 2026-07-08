clear
close all force

% Change current working directory to the directory where this file is
cd(fileparts(mfilename('fullpath')));
addpath(genpath('../../'))

% Data should be moved locally. Using this GUI with data stored on the LRS
% is slow
data_file_path = "Y:\";
% data_file_path = "R:\ENG_Breuer_Shared\group\Wind turbine\Turbine_STB\Turbine_STB_02_17_2026\Processed Data\";

% GUI for plotting vector fields and wake topology
% a = flowField_UI(1,data_file_path);
% a.dynamic_plotting();

% GUI for plotting instantaneous vector fields before phase averaging
% b = flowFieldInst_UI(1,data_file_path);
% b.dynamic_plotting();

% % GUI for plotting phase averaged quantities
c = phaseAvg_UI(1,data_file_path);
c.dynamic_plotting();

% % GUI for plotting time averaged quantities
% d = timeAvg_UI(1, data_file_path);
% d.dynamic_plotting();