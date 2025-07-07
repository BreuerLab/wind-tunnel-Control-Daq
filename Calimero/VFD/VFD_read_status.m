function Modbusdata = VFD_read_status
% Read the MODBUS
% Read 5 Holding Registers of type 'uint16' starting from address 102.

modbus = VFD_initialize;

if modbus.ServerID > 0
    data = read(modbus.Handle, 'holdingregs', 102, 5, modbus.ServerID, 'uint16');
    % acel = read(modbus.Handle, 'holdingregs', 2202, 6, modbus.ServerID, 'uint16');
    
    % Read the status word
    SW   = read(modbus.Handle, 'holdingregs', 4,  1, modbus.ServerID, 'uint16');
else
    %fprintf('%s: simulating VFD read', datetime)
    data = 20*ones(1,5);
    SW = 0;
end

%                                    Parameter
Modbusdata.RPM       = data(1);      % 102
Modbusdata.Frequency = data(2);      % 103
Modbusdata.Current   = data(3)/10;   % 104
Modbusdata.Torque    = data(4);      % 105
Modbusdata.Power     = data(5)/10;   % 106
Modbusdata.StatusWord = SW;
% fprintf("SW: %X\n", SW);
% Modbusdata.Accel     = acel;

return

