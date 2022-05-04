% This function moves the MPS pitch axis so that its state matches that of
% a structure (pitch) with four fields (ACC, DCC, V, P) that have units of
% RPM/s, RPM/s, RPM, and counts respectively.

% Wind Tunnel: AFAM with MPS

% pitch_move.m
% Siyang Hao, Cameron Urban
% 05/04/2022

function pitch_move(pitch)

% TODO: Determine what units these are converting from.
% Create conversion variables (to_rpm_per_s, to_rpm, steps_per_count). 
mps_to_rpm_per_s = 1 / 17476.3;
mps_to_rpm = 1 / 17476.3;
steps_per_count = 16.0;

% Calculate the acceleration, deceleration, velocity, and counts of the
% motion in MPS units.
acc_to_write = uint64(pitch.ACC / mps_to_rpm_per_s);
dec_to_write = uint64(pitch.DEC / mps_to_rpm_per_s);
v_to_write = uint32(pitch.V / mps_to_rpm);
p_to_write = int32(pitch.P * steps_per_count);

% Create a modbus object, a variable to hold the server's ID, and an
% address offset variable.
this_bus = modbus("tcpip", "192.168.1.202");
this_bus.Timeout = 3;
offset = 1;

% TODO: What is the purpose of these two lines.
% Write 1s to the num and load addresses.
write(this_bus,"holdingregs", 548+offset, 1, "int32");
write(this_bus,"holdingregs", 542+offset, 1, "int32");

% Write the motion parameters to their respective addresses.
write(this_bus,"holdingregs", 526+offset, double(acc_to_write), "int64");
write(this_bus,"holdingregs", 536+offset, double(dec_to_write), "int64");
write(this_bus,"holdingregs", 566+offset, double(v_to_write), "int32");
write(this_bus,"holdingregs", 550+offset, double(p_to_write), "int64");

% Write a 1 to the control address to specify relative motion mode.
write(this_bus,"holdingregs", 532+offset, 1, "int32");

% Set the motion parameters by writing a 1 to the set address.
write(this_bus,"holdingregs", 554+offset, 1, "int32");

% Move the motor based on the set motion parameters by writing a 1 to the
% move address.
write(this_bus,"holdingregs", 544+offset, 1, "int32");

% Delete the modbus object we created.
clear this_bus;

return