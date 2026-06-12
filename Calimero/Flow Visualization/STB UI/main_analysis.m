clear
% close all force

% Change current working directory to the directory where this file is
cd(fileparts(mfilename('fullpath')));
addpath(genpath('../../../'))

% Data should be moved locally. Using this GUI with data stored on the LRS
% is slow
data_file_path = "Y:\";
% data_file_path = "R:\ENG_Breuer_Shared\group\Wind turbine\Turbine_STB\Turbine_STB_02_17_2026\Processed Data\";

% GUI for plotting vector fields and wake topology
% c = flowField_UI(2,data_file_path);
% c.dynamic_plotting();

% % GUI for plotting phase averaged quantities
% a = phaseAvg_UI(2,data_file_path);
% a.dynamic_plotting();

% % GUI for plotting time averaged quantities
b = timeAvg_UI(2, data_file_path);
b.dynamic_plotting();