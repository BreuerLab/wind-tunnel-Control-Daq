function [OF_cur, distFromZero] = speedLoop(des_freq, OF_init, galil, dmc_motion_filename,...
    dmc_stop_filename, flapper_obj, case_name, distFromZero)
    tic
    case_name = case_name + "_speedCheck_";
    [cur_freq, distFromZero] = checkSpeed(OF_init, galil, dmc_motion_filename, dmc_stop_filename,...
        flapper_obj, case_name + "1", distFromZero);
    disp("Current freq: " + cur_freq)
    err = des_freq - cur_freq;
    disp(err)
    OF_cur = OF_init;

    idx = 2;
    thresh = 0.1;
    while (abs(err) > thresh && idx < 11)
        k = 0.012;
        OF_cur = OF_cur + round(err*k,4);
        disp("Testing OF: " + OF_cur)
        % max resolution on OF is 20/65536 = 0.000305
        if abs(OF_cur) > 0.5
            OF_cur = 0.5;
            disp("OF cannot exceed 0.5");
        elseif OF_cur < 0
            error("OF cannot be less than zero");
        elseif OF_cur < 0.18
            OF_cur = 0.18;
            disp("Cannot go less than OF 0.18")
        end

        [cur_freq, distFromZero] = checkSpeed(OF_cur, galil, dmc_motion_filename, dmc_stop_filename,...
            flapper_obj, case_name + string(idx), distFromZero);

        disp("Current freq: " + cur_freq)
        err = des_freq - cur_freq;
        idx = idx + 1;
        pause(0.2)
    end
    disp("Loop complete, took " + idx + " iterations to find wingbeat frequency")
    disp("Remaining error: " + err + ", Threshold: " + thresh)
    toc
end