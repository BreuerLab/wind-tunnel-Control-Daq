function OF_cur = speedLoop(des_freq, OF_init, galil, dmc_motion_filename, dmc_stop_filename, flapper_obj, cal_matrix, case_name)
    tic
    case_name = case_name + "_speedCheck_";
    cur_freq = checkSpeed(OF_init, galil, dmc_motion_filename, dmc_stop_filename,...
        flapper_obj, cal_matrix, case_name + "1");
    disp("Current freq: " + cur_freq)
    err = des_freq - cur_freq;
    disp(err)
    OF_cur = OF_init;

    idx = 2;
    thresh = 0.1;
    while (abs(err) > thresh)
        k = 0.02;
        OF_cur = OF_cur + round(err*k,3);
        % max resolution on OF is 20/65536 = 0.000305
        if abs(OF_cur) > 0.5
            error("OF cannot exceed 0.5");
        elseif OF_cur < 0
            error("OF cannot be less than zero");
        end

        cur_freq = checkSpeed(OF_cur, galil, dmc_motion_filename, dmc_stop_filename,...
            flapper_obj, cal_matrix, case_name + string(idx));

        disp("Current freq: " + cur_freq)
        err = des_freq - cur_freq;
        idx = idx + 1;
    end
    disp("Loop complete, took " + idx + " iterations to find wingbeat frequency")
    disp("Remaining error: " + err + ", Threshold: " + thresh)
    toc
end