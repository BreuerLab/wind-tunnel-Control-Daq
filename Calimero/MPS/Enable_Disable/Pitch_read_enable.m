function P = Pitch_read(Pitch)

% Read the status of the pitch axis
% Kenny Breuer April 2021
%
% updated to include initialization routine.  Jan 2022
%
% TODO = get a "practical" value of the position readout
%

% if exist('Pitch.Initialized') == 0
%     fprintf("Pitch axis not initialized - calling Pitch_initialize")
%     Pitch = Pitch_initialize;
%     return
% end

% Create a Modbus Object.
m = modbus('tcpip', Pitch.AXIS_ADDRESS);
mData.Timeout = 3;
serverId = 1;

IOFF = Pitch.IOFF; % This seems to be necessary to get the addresses correct

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

P.ACC = bitand(mData.ACC , 0xFFFFFFFF) / Pitch.ACC_Conversion;
P.DEC = bitand(mData.DEC , 0xFFFFFFFF) / Pitch.DEC_Conversion;
P.V   = bitshift(mData.V, -32) /  Pitch.V_Conversion;
P.P   = int32(mData.P / Pitch.P_Conversion);
P.POS = mData.POS;
P.OFF = mData.OFF;
P.PLS = mData.PLS;  % Limit switch status
P.PLM = mData.PLM;  % Limit switch mode

P.position = P.P;   % Need to define this, but this will do for now

if Pitch.Report
    fprintf('*** [Pitch Read: \n')
    fprintf('  ACC: %16.16X; [%10.3f RPM/s]\n', mData.ACC, bitand(mData.ACC , 0xFFFFFFFF)/Pitch.ACC_Conversion);
    fprintf('  DEC: %16.16X; [%10.3f RPM/s]\n', mData.DEC, bitand(mData.DEC , 0xFFFFFFFF)/Pitch.DEC_Conversion);
    fprintf('    V: %16.16X; [%10.3f RPM]\n',   mData.V, bitshift(mData.V, -32)/  Pitch.V_Conversion);
    fprintf('    P: %16.16X; [%10.3f Counts; %10.3f Degrees]\n', uint64(mData.P),  Pitch.P, Pitch.P/Pitch.P_Conversion);
    fprintf('  POSITION:  %16.16X [HEX]; %ld [INT]; %12.3f [COUNTS]\n', mData.POS, mData.POS, mData.POS/16.);
    fprintf('  OFFSET:    %ld\n', mData.OFF);
    fprintf('  PL Status: %d \n', mData.PLS);
    fprintf('  PL Mode:   %d \n', mData.PLM);
    fprintf('Pitch Read] ***\n')
end

% Now Write to the offset register to zero out the reading.
% write(m,'holdingregs', 290+IOFF, 54484850, 'int64');

% Clear the Modbus Object created.
clear m
clear serverId

return