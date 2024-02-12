function status = Pitch_enable(Pitch)

% ENABLE the pitch axis
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

% Check that the motor is not already moving
MOVING = 1;
while MOVING
    STATUS = uint32(read(m, 'holdingregs', 268+Pitch.IOFF, 1, serverId, 'uint32'));
    MOVING = bitand(STATUS, uint32(0x01));
    pause(0.30);
end

%% Write the command to both Stop and enable to MODBUS.DRV (Reg 942)
% :   Set Bit 0  = 1  (STOP)
%             1  = 1 in MODBUS.DRV  (address: 942)
write(m,'holdingregs', 254+Pitch.IOFF, 1, 'int32'); % DRV.EN
pause(2)  % Wait two seconds  (arbitrary)

%% Clear the Modbus Object created.
clear m
clear serverId

status = 0
return