function [frame_rate, num_wingbeats] = get_sampling_info(wing_freq)

    frame_rate = 10000; % DAQ data sampling rate (Hz)

    % Number of wingbeats recorded for each trial
    if (wing_freq > 0.5)
        num_wingbeats = 180;
    else
        num_wingbeats = 12;
    end

end