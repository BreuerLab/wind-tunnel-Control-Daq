function [frame_rate, num_wingbeats, rec_wingbeats] = get_sampling_info(wing_freq)

    frame_rate = 12000; % DAQ data sampling rate (Hz)

    % Number of wingbeats recorded for each trial
    if (wing_freq > 0.5)
        num_wingbeats = 180;
    else
        num_wingbeats = 12;
    end

    num_wingbeats = 50;

    acc = 3;
    padding_revs = 4;
    hold_time = 15;
    [rec_wingbeats, ~] = estimate_duration(wing_freq, acc, num_wingbeats, padding_revs, hold_time, true);

end