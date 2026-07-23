function improved_motor_control(galil, dmc_get_FF_filename, dmc_play_FF_filename,...
    dmc_params, measure_revs, num_revs, at_speed_pos, freq, acc, padding_revs)

galil.command('DA *,*[0]'); % deallocate memory
% Run script to collect torque profile over motion
disp("Collecting torque profile")
measure_revs_temp = 50; % revolutions to measure at desired speed
phase_avg_voltCmd = collect_torque_profile(galil, dmc_get_FF_filename, dmc_params,...
    measure_revs_temp, freq, acc, padding_revs);

% Send phase averaged torque to galil
% galil.command('RC 0');
galil.command('HX'); % Halt Execution of all threads
galil.command('DR 0'); % Turn off Data Record sampling if active
galil.command('DA *,*[0]'); % deallocate memory
galil.command(['DM Torque[' num2str(length(phase_avg_voltCmd)) ']']);
% galil.arrayDownload(phase_avg_voltCmd, 'Torque'); % send array to galil

for i = 0:127
    galil.command(sprintf('Torque[%d] = %.6f', i, phase_avg_voltCmd(i+1)));
end

% Run new benchtop test with feedforward control
run_FF_motion(galil, dmc_play_FF_filename, dmc_params, measure_revs, num_revs,...
    freq, acc, at_speed_pos, padding_revs, phase_avg_voltCmd);

end