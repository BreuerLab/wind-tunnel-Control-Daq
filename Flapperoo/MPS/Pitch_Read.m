function Pitch = Pitch_Read(print_bool)

% Conversion factors:
ACC_Conversion = 17476.3; % to RPM/sec
DEC_Conversion = 17476.3; % to RPM/sec
  V_Conversion = 17476.3; % to RPM
  P_Conversion = 16.0;    % to counts (still need to convert to degrees)
POS_Conversion = 1.0;     % counts

% Create a Modbus Object.
m = modbus('tcpip', '192.168.1.202');
mData.Timeout = 3;
serverId = 1;

IOFF = 1; % This seems to be necessary to get the addresses correct


% Uncomment to read a whole bank of addresses:
% ISTART = 526;
% mData.TOTAL = read(m, 'holdingregs', ISTART+IOFF, 4*20, serverId, 'uint16');
% 
% for i = 1:4:length(mData.TOTAL)
%     fprintf('%4d: %4.4X %4.4X %4.4X %4.4X \n', ISTART+i-1, mData.TOTAL(i:i+3))
% end

% Read from the modbus: 
mData.OFF = read(m, 'holdingregs', 290+IOFF, 1, serverId, 'uint64');
mData.ACC = read(m, 'holdingregs', 526+IOFF, 1, serverId, 'uint64'); 
mData.DEC = read(m, 'holdingregs', 536+IOFF, 1, serverId, 'uint64');
mData.P   = read(m, 'holdingregs', 552+IOFF, 1, serverId, 'int32');
mData.V   = read(m, 'holdingregs', 566+IOFF, 1, serverId, 'int64');
mData.POS = read(m, 'holdingregs', 588+IOFF, 1, serverId, 'int64');
mData.PLS = read(m, 'holdingregs', 618+IOFF, 1, serverId, 'int32');
mData.PLM = read(m, 'holdingregs', 620+IOFF, 1, serverId, 'int32');

Pitch.ACC = bitand(mData.ACC , 0xFFFFFFFF)/ACC_Conversion;
Pitch.DEC = bitand(mData.DEC , 0xFFFFFFFF)/DEC_Conversion;
Pitch.V   = bitshift(mData.V, -32)/  V_Conversion;
Pitch.P   = int32(mData.P /  P_Conversion);
Pitch.POS = mData.POS;
Pitch.OFF = mData.OFF;
Pitch.PLS = mData.PLS;  % Limit switch status
Pitch.PLM = mData.PLM;  % Limit switch mode

if (print_bool)
fprintf('ACC: %16.16X; [%10.3f RPM/s]\n', mData.ACC, bitand(mData.ACC , 0xFFFFFFFF)/ACC_Conversion);
fprintf('DEC: %16.16X; [%10.3f RPM/s]\n', mData.DEC, bitand(mData.DEC , 0xFFFFFFFF)/DEC_Conversion);
fprintf('  V: %16.16X; [%10.3f RPM]\n',   mData.V, bitshift(mData.V, -32)/  V_Conversion);
fprintf('  P: %16.16X; [%10.3f Counts]\n', uint64(mData.P),  Pitch.P);
fprintf('POSITION:  %ld \n', mData.POS);
fprintf('OFFSET:    %ld \n', mData.OFF);
fprintf('PL Status: %d \n', mData.PLS);
fprintf('PL Mode:   %d \n', mData.PLM);
end

% Now Write to the offset register to zero out the reading.
% write(m,'holdingregs', 290+IOFF, 54484850, 'int64');

% Clear the Modbus Object created.
clear m
clear serverId

return