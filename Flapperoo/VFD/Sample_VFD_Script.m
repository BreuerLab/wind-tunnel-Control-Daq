%% This is a sample script that you can incorporate into a MATLAB script
%
% First of all:
% * the VFD must be switched ON
% * the AFAM_Unified script must be running first - if not, the
%   code will return an error message
%
% Kenny Breuer, May 2022
%

% Start the motor - this will start at whatever the previous value of the
% speed was

disp('VFD Demo: Hit any key to start the motor')
pause;
VFD_start;



disp('Hit any key to increase the speed')
pause;

% Set a speed in RPM 
VFD_set_RPM(100);

disp('Hit any key to stop the VFD')
pause;

% Stop the motor
VFD_stop;

