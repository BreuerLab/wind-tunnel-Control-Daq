function galil_traj_plot_DR(galil_data, dt)

% Used to debug to figure out which values are changing in time
% ----------------------------------------------------------------
% % Compute differences along rows
% dA = diff(galil_data,1,2);
% 
% % Loop or cell array to store indices where change occurs
% changeIdx = arrayfun(@(i) find(dA(i,:) ~= 0), 1:size(dA,1), 'UniformOutput', false);
% changeIdx = changeIdx';
% ----------------------------------------------------------------

ticksPerRev = 18432;
AG = 0.4;
dt = dt*0.976; % in ms, for TM1000, corresponds to 0.976 ms

ref_pos = get_long(83, 86, galil_data); % Reference Position A
ref_pos = ref_pos / ticksPerRev;

act_pos = get_long(87, 90, galil_data); % Measured Position A
act_pos = act_pos / ticksPerRev;

act_vel = get_long(99, 102, galil_data); % Measured Velocity A
act_vel = act_vel / (ticksPerRev*64);

torque = get_long(103, 106, galil_data);
voltCommand = torque * (10 / 32767); % motor command in volts, 10 V for every 32767 (see RD in command reference for Galil)
current = AG * voltCommand * 1000; % current in mA

time = 0:1:length(ref_pos)-1;
time = time * (dt/1000); % time in seconds

% findSpeedVariation(time, act_vel)

figure
hold on
plot(time, ref_pos, DisplayName="Desired Position")
plot(time, act_pos, DisplayName="Actual Position")
xlabel("Time (s)")
ylabel("Revolutions")
legend(Location="best")
set(findall(gca, 'Type', 'Line'), 'LineWidth', 2);
set(gca, FontSize=14);

figure
hold on
yyaxis left
plot(time, act_vel, DisplayName="Velocity")
ylabel("Revolutions per second")
yyaxis right
plot(time, current, DisplayName="Current")
ylabel("Current (mA)")
legend(Location="best")
set(findall(gca, 'Type', 'Line'), 'LineWidth', 2);
set(gca, FontSize=14);

% 83 - 86: Reference Position A
% corresponding to addresses 82-85 because of 0 address, while addresses in
% manual are 86-89, so it's shifted by 4 bytes, so maybe we still have the
% last 4 bytes associated with F axis user data, while we lost 4 bytes
% elsewhere
% the ethernet handles for G & H may have been dropped (that's 2 bytes)
% 87 - 90: Measured Position A
% 99 - 102: Measured Velocity A
end