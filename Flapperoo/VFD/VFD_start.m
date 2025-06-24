function VFD_start
% start sequence for the tunnel
%
% Note that this does not set the speed to zero
%
% Kenny Breuer May 2022

modbus = VFD_initialize;

if modbus.ServerID > 0
    write(modbus.Handle,'holdingregs',1, 1150, 'uint16');
    pause(.3)
    write(modbus.Handle,'holdingregs',1, 1030, 'uint16');
    pause(.3)
    write(modbus.Handle,'holdingregs',1, 1151, 'uint16');
    pause(.3)
else
    disp('Simulating starting the tunnel')
end

return
