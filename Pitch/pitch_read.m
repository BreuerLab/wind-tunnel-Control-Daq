% TODO: Document this function.
function pitch = pitch_read

% Conversion factors:
ACC_Conversion = 17476.3; % to RPM/sec
DEC_Conversion = 17476.3; % to RPM/sec
V_Conversion = 17476.3; % to RPM
P_Conversion = 16.0;    % to counts (still need to convert to degrees)

% Create a Modbus Object.
m = modbus("tcpip", "192.168.1.202");
mData.Timeout = 3;
serverId = 1;

IOFF = 1; % This seems to be necessary to get the addresses correct

% Read from the modbus: 
mData.OFF = read(m, "holdingregs", 290+IOFF, 1, serverId, "uint64");
mData.ACC = read(m, "holdingregs", 526+IOFF, 1, serverId, "uint64"); 
mData.DEC = read(m, "holdingregs", 536+IOFF, 1, serverId, "uint64");
mData.P   = read(m, "holdingregs", 552+IOFF, 1, serverId, "int32");
mData.V   = read(m, "holdingregs", 566+IOFF, 1, serverId, "int64");
mData.POS = read(m, "holdingregs", 588+IOFF, 1, serverId, "int64");
mData.PLS = read(m, "holdingregs", 618+IOFF, 1, serverId, "int32");
mData.PLM = read(m, "holdingregs", 620+IOFF, 1, serverId, "int32");

pitch.ACC = bitand(mData.ACC , 0xFFFFFFFF)/ACC_Conversion;
pitch.DEC = bitand(mData.DEC , 0xFFFFFFFF)/DEC_Conversion;
pitch.V   = bitshift(mData.V, -32)/  V_Conversion;
pitch.P   = int32(mData.P /  P_Conversion);
pitch.POS = mData.POS;
pitch.OFF = mData.OFF;
pitch.PLS = mData.PLS;  % Limit switch status
pitch.PLM = mData.PLM;  % Limit switch mode

% Clear the Modbus Object created.
clear m;
clear serverId;

return