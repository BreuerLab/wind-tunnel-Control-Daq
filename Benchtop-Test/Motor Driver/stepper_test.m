% Author: Ronan Gissler
% Adapted from code written by Xiaozhou and Cameron
% November 2022

dmc_file_name = "stepper_test.dmc";

% Create the carraige return and linefeed variable from the .dmc file.
dmc = fileread(dmc_file_name);
dmc = string(dmc);

% Connect to the Galil device.
galil = actxserver("galil");

% Set the Galil object's address to match the device's address
% IP address should be printed on sticker on Galil
galil.address = "192.168.1.20";

% Get Model Number
response = galil.command(strcat(char(18), char(22)));
disp(strcat("Connected to: ", response));

% Load the program described by the .dmc file to the Galil device.
galil.programDownload(dmc);

% Execute program
galil.command("XQ");