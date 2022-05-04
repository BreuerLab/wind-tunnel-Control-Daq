% This function reads the current state of the MPS pitch axis. It returns
% as structure (pitch) with five fields (ACC, DCC, V, P, POS) that have
% units of RPM/s, RPM/s, RPM, counts, and steps respectively.

% Wind Tunnel: AFAM with MPS

% pitch_read.m
% Siyang Hao, Cameron Urban
% 05/04/2022

function pitch = pitch_read

% TODO: Determine what units these are converting from.
% Create conversion variables (to_rpm_per_s, to_rpm, steps_per_count). 
mps_to_rpm_per_s = 1 / 17476.3;
mps_to_rpm = 1 / 17476.3;
steps_per_count = 16.0;

% Create a modbus object, a variable to hold the server's ID, and an
% address offset variable.
this_bus = modbus("tcpip", "192.168.1.202");
this_bus.Timeout = 3;
server_id = 1;
offset = 1;

% Read data from the modbus.
bus_data.ACC = read(this_bus, "holdingregs", 526 + offset, 1, server_id,...
    "uint64"); 
bus_data.DEC = read(this_bus, "holdingregs", 536 + offset, 1, server_id,...
    "uint64");
bus_data.P   = read(this_bus, "holdingregs", 552 + offset, 1, server_id,...
    "int32");
bus_data.V   = read(this_bus, "holdingregs", 566 + offset, 1, server_id,...
    "int64");
bus_data.POS = read(this_bus, "holdingregs", 588 + offset, 1, server_id,...
    "int64");

% TODO: Find the difference between bus_data.P and bus_data.POS.
% Convert the modbus data and save it to the structure.
pitch.ACC = bitand(bus_data.ACC , 0xFFFFFFFF) * mps_to_rpm_per_s;
pitch.DEC = bitand(bus_data.DEC , 0xFFFFFFFF) * mps_to_rpm_per_s;
pitch.V   = bitshift(bus_data.V, -32) * mps_to_rpm;
pitch.P   = int32(bus_data.P / steps_per_count);
pitch.POS = bus_data.POS;

% Delete the modbus object we created.
clear this_bus;

return