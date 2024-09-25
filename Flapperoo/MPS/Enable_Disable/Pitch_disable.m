function status = Pitch_disable(Pitch)

% Disable the pitch axis
%
% Kenny Breuer, Oct 2023
% 

% if ~exist(Pitch.Initialized)
%     fprintf("Pitch axis not initialized - call Pitch_Initialize first")
%     status = -1;
%     return
% end


%% Create a Modbus Object.
m = modbus('tcpip', Pitch.AXIS_ADDRESS);
m.Timeout = 3;
serverId  = 1;

%% Write the disable 
write(m,'holdingregs', 236+Pitch.IOFF, 1, 'int32'); % DRV.DIS

%% Clear the Modbus Object created.
clear m
clear serverId

status = 0;
return