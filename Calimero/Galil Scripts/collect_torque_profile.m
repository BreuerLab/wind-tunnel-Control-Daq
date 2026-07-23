function phase_avg_voltCmd_interp = collect_torque_profile(galil, dmc_get_FF_filename, dmc_params,...
    measure_revs, freq, acc, padding_revs)

    hold_time = 10; % sec, irrelevant, only used for gliding trials
    % estimate recording length based on parameters
    [num_revs, session_duration, ~, at_speed_pos] = ...
    estimate_duration(freq, acc, measure_revs, padding_revs, hold_time, dmc_params.wait_time, true);

    dmc = fileread(dmc_get_FF_filename);
    dmc = string(dmc);
    % Replace the place holders in the .dmc file with the values specified
    % here. Other parameters can be changed directly in .dmc file.
    if dmc_params.galil_direction == 1
        dmc = strrep(dmc, "dir_TEMP", "2");
    else
        dmc = strrep(dmc, "dir_TEMP", "0");
    end

    dmc = strrep(dmc, "revs_TEMP", num2str(num_revs));
    dmc = strrep(dmc, "ticks_TEMP", num2str(dmc_params.ticksPerRev));
    dmc = strrep(dmc, "speed_TEMP", num2str(freq));
    dmc = strrep(dmc, "acc_TEMP", num2str(acc));
    dmc = strrep(dmc, "waittime_TEMP", num2str(dmc_params.wait_time));
    dmc = strrep(dmc, "OC_TEMP", num2str(dmc_params.OC_pulse_step));
    dmc = strrep(dmc, "revsRec_TEMP", num2str(round(at_speed_pos) + padding_revs));
    
    % Load the program described by the .dmc file to the Galil device.
    galil.programDownload(dmc);
    % Command the galil to execute the program (default on thread 0)
    galil.command("XQ");

    pause(session_duration)
    % pause(0.5)
    % % Wait for program to finish running
    % while str2double(galil.command('MG _XQ')) ~= -1
    %     pause(0.2); % Pause 50ms to avoid pegging MATLAB's CPU
    % end

    TM = 1000; % TM 1000 corresponds to 976 microseconds, 1 increment in TM for every 1000
    TimeArr = galil.arrayUpload('TimeArr');
    TimeArr = cell2mat(TimeArr);
    TimeArr = ((TimeArr - TimeArr(1)) * (TM / 1000) * 0.976) / 1000; % increments by 1 every 976 microseconds
    dt = round(TimeArr(2) - TimeArr(1),4);
    I = find(round(diff(TimeArr),4) ~= dt, 1, "first");
    if isempty(I)
        disp("Oops, no ending index found...")
        I = length(TimeArr);
    end

    % Get torque signal from galil
    torque = galil.arrayUpload('Torque');
    torque = cell2mat(torque);
    voltCmd = torque * (10 / 32767); % motor command in volts, 10 V for every 32767 (see RD in command reference for Galil)

    DesPos = galil.arrayUpload('DesPos');
    DesPos = cell2mat(DesPos);
    DesPos = DesPos / dmc_params.ticksPerRev;
    
    ActPos = galil.arrayUpload('ActPos');
    ActPos = cell2mat(ActPos);
    ActPos = ActPos / dmc_params.ticksPerRev;

    startPos = ceil(min(ActPos));
    endPos = floor(max(ActPos));
    ActPos_trimmed = ActPos(ActPos >= startPos & ActPos <= endPos);
    voltCmd_trimmed = voltCmd(ActPos >= startPos & ActPos <= endPos);

    nextRev_idx = find(diff(mod(ActPos_trimmed,1)) < 0) + 1;

    num_wingbeats = length(nextRev_idx);
    voltCmd_wingbeats = zeros(num_wingbeats,nextRev_idx(1) - 1);
    ActPos_wingbeats = zeros(num_wingbeats,nextRev_idx(1) - 1);
    cur_idx = 1;
    for i = 1:num_wingbeats
        end_idx = nextRev_idx(i) - 1;

        cur_wingbeat_voltCmd = voltCmd_trimmed(cur_idx:end_idx);
        % cur_wingbeat_resampled = resample(cur_wingbeat.', frames_per_beat, length(cur_wingbeat)).';
        voltCmd_wingbeats(i,:) = cur_wingbeat_voltCmd;

        cur_wingbeat_ActPos = mod(ActPos_trimmed(cur_idx:end_idx),1);
        ActPos_wingbeats(i,:) = cur_wingbeat_ActPos;

        cur_idx = nextRev_idx(i);
    end

    phase_avg_voltCmd = mean(voltCmd_wingbeats,1);
    phase_avg_ActPos = mean(ActPos_wingbeats,1);

    numPts = 128;
    dx = 1 / numPts;
    pos = 0:dx:(1-dx);

    phase_avg_voltCmd_interp = interp1(phase_avg_ActPos, phase_avg_voltCmd, pos, 'linear','extrap');
end