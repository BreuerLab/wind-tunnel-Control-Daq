function improved_motor_control(galil, dmc_get_FF_filename, dmc_play_FF_filename,...
    dmc_params, measure_revs, num_revs, at_speed_pos, freq, acc, padding_revs)

ILC_bool = true;
if ~ILC_bool
galil.command('DA *,*[0]'); % deallocate memory
% Run script to collect torque profile over motion
disp("Collecting torque profile")
measure_revs_temp = 40; % revolutions to measure at desired speed
phase_avg_voltCmd = collect_torque_profile(galil, dmc_get_FF_filename, dmc_params,...
    measure_revs_temp, freq, acc, padding_revs, 0);

% phase_avg_voltCmd = circshift(phase_avg_voltCmd,1);

% rescale voltage command to not be so aggressive
phase_avg_voltCmd = phase_avg_voltCmd / 2;
% phase_avg_voltCmd = phase_avg_voltCmd - min(phase_avg_voltCmd);

fc = 2;
fs = 128;
[b,a] = butter(6,fc/(fs/2));
phase_avg_voltCmd = filtfilt(b,a,phase_avg_voltCmd);

% Send phase averaged torque to galil
galil.command('RC 0');
galil.command('HX'); % Halt Execution of all threads
galil.command('DR 0'); % Turn off Data Record sampling if active
galil.command('DA *,*[0]'); % deallocate memory
galil.command(['DM voltCmd[' num2str(length(phase_avg_voltCmd)) ']']);
% galil.arrayDownload(phase_avg_voltCmd, 'Torque'); % send array to galil

for i = 0:127
    galil.command(sprintf('voltCmd[%d] = %.6f', i, phase_avg_voltCmd(i+1)));
end

% dmc_get_FF_filename = "obtain_cycle_torque_FF.dmc";
% phase_avg_voltCmd = collect_torque_profile(galil, dmc_get_FF_filename, dmc_params,...
%     measure_revs_temp, freq, acc, padding_revs, length(phase_avg_voltCmd));

% % Send phase averaged torque to galil
% galil.command('RC 0');
% galil.command('HX'); % Halt Execution of all threads
% galil.command('DR 0'); % Turn off Data Record sampling if active
% galil.command('DA *,*[0]'); % deallocate memory
% galil.command(['DM voltCmd[' num2str(length(phase_avg_voltCmd)) ']']);
% % galil.arrayDownload(phase_avg_voltCmd, 'Torque'); % send array to galil
% 
% for i = 0:127
%     galil.command(sprintf('voltCmd[%d] = %.6f', i, phase_avg_voltCmd(i+1)));
% end

% Run new benchtop test with feedforward control
run_FF_motion(galil, dmc_play_FF_filename, dmc_params, measure_revs, num_revs,...
    freq, acc, at_speed_pos, padding_revs, phase_avg_voltCmd);

%   P_STRT = _TPA      ; 'Obtain current motor position
% s_IDX = (IDX + 1);
%     IF (s_IDX >= NUM_SAMPLES_TEMP)
%       s_IDX = s_IDX - NUM_SAMPLES_TEMP;
%     ENDIF

    % AP (p_strt + (cur_rev*ticks_TEMP) + (idx*step_sz) + shift);
    % OFA = voltCmd[idx];
    % idx = idx + 1;
    % AP (p_strt + (cur_rev*ticks_TEMP) + (idx*step_sz) + shift);

else


    % V_ACT = _TVA;                      ' Actual velocity in counts/sec
    % err = (V_DES - V_ACT) / ticks_TEMP;

galil.command('RC 0');
galil.command('HX'); % Halt Execution of all threads
galil.command('DR 0'); % Turn off Data Record sampling if active
galil.command('DA *,*[0]'); % deallocate memory

phase_avg_voltCmd = zeros(1,64);
% ---------------------------------------------------------------------
galil.command(['DM voltCmd[' num2str(length(phase_avg_voltCmd)) ']']);
% galil.arrayDownload(phase_avg_voltCmd, 'Torque'); % send array to galil

for i = 0:length(phase_avg_voltCmd)-1
    galil.command(sprintf('voltCmd[%d] = %.6f', i, phase_avg_voltCmd(i+1)));
end

dmc_play_FF_filename = "benchtop_test_FF_ILC.dmc";
run_FF_motion(galil, dmc_play_FF_filename, dmc_params, measure_revs, num_revs,...
    freq, acc, at_speed_pos, padding_revs, phase_avg_voltCmd);

    % new_trq = (0.50*new_trq[s_idx]) + (0.25*new_trq[s_idx+1]);
    % new_trq = new_trq + (0.25*new_trq[s_idx-1]);
end

end