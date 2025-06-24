function VFD_stop

% Code to turn the motor OFF
% Code: 1148 coasts to a stop, 1150 uses active braking
% 1148 works, but coasting code might be 1149
%
% Kenny Breuer May 2022

modbus = VFD_initialize;
if modbus.ServerID > 0
    write(modbus.Handle,'holdingregs',1, 1150, 'uint16');
else
    disp('Simulating shutting down tunnel')    
end


return