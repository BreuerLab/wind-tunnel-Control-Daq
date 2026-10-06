function [frame_rate, num_wingbeats, rec_wingbeats, ticksPerRev, OC_pulse_step] = get_sampling_info(wing_freq)

    frame_rate = 12000; % DAQ data sampling rate (Hz)

    % Number of wingbeats recorded for each trial
    if (wing_freq > 0.5)
        num_wingbeats = 180;
    else
        num_wingbeats = 12;
    end

    % num_wingbeats = 50;

    acc = 3;
    padding_revs = 4;
    % some random line
    hold_time = 15;
    wait_time = 4000; % ms
    print_bool = false;
    [rec_wingbeats, ~, ~, ~] = estimate_duration(wing_freq, acc, num_wingbeats, padding_revs, hold_time, wait_time, print_bool);

    ticksPerRev = 18432;
    OC_pulse_step = 4;

end