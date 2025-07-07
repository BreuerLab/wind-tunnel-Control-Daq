function Pitch_Move(Pitch)

% Move according to the structure Pitch

% Conversion factors:
ACC_Conversion = 17476.3; % to RPM/sec
DEC_Conversion = 17476.3; % to RPM/sec
  V_Conversion = 17476.3; % to RPM
  P_Conversion = 16.0;    % to counts (still need to convert to degrees)
POS_Conversion = 1.0;     % counts

IOFF = 1; % This seems to be necessary to get the addresses correct


% Prepare the word for the Modbus
mbus.ACC = uint64(Pitch.ACC*ACC_Conversion);
mbus.DEC = uint64(Pitch.DEC*DEC_Conversion);
mbus.V   = uint32(Pitch.V*V_Conversion);
mbus.P   =  int32(Pitch.P*P_Conversion);

% fprintf('DEC: %16.16X\n', mbus.DEC);
% fprintf('ACC: %16.16X\n', mbus.ACC);
% fprintf('  V: %16.16X\n', mbus.V);
% fprintf('  P: %16.16X\n', mbus.P);


% Create a Modbus Object.
m = modbus('tcpip', '192.168.1.202');
m.Timeout = 3;
serverId = 1;

% Program Motion Task 1
write(m,'holdingregs', 548+IOFF, 1,                'int32'); % MT.NUM 1
write(m,'holdingregs', 542+IOFF, 1,                'int32'); % MT.LOAD

% Write the motion parameters
write(m,'holdingregs', 526+IOFF, double(mbus.ACC), 'int64'); % MT.ACC
write(m,'holdingregs', 536+IOFF, double(mbus.DEC), 'int64'); % MT.DEC
write(m,'holdingregs', 566+IOFF, double(mbus.V),   'int32'); % MT.V
write(m,'holdingregs', 550+IOFF, double(mbus.P),   'int64'); % MT.P
write(m,'holdingregs', 532+IOFF, 1,                'int32'); % MT.CTRL 1 (relative motion)

% Set the motion parameters
write(m,'holdingregs', 554+IOFF, 1,                'int32'); % MT.SET

% Move (uncomment to actually move the motor)
write(m,'holdingregs', 544+IOFF, 1,                'int32'); % MT.MOVE


% Clear the Modbus Object created.
clear m
clear serverId

return