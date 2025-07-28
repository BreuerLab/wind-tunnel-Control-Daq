function OF_cur = speedLoop(des_freq, OF_init, galil, dmc_motion_filename, dmc_stop_filename, flapper_obj, cal_matrix, case_name)
    tic
    case_name = case_name + "_speedCheck_";
    cur_freq = checkSpeed(OF, galil, dmc_motion_filename, dmc_stop_filename,...
        flapper_obj, cal_matrix, case_name + "1");
    err = abs(des_freq - cur_freq);
    OF_old = OF_init;

    idx = 2;
    thresh = 0.1;
    while (err > thresh)
        k = 0.01;
        OF_cur = OF_old + round(err*k,3);
        % max resolution on OF is 20/65536 = 0.000305
        if Of_cur > 0.5
            error("OF cannot exceed 0.5");
        end

        cur_freq = checkSpeed(OF_init, galil, dmc_motion_filename, dmc_stop_filename,...
            flapper_obj, cal_matrix, case_name + string(idx));
        err = abs(des_freq - cur_freq);
        idx = idx + 1;
    end
    disp("Loop complete, took " + idx + " iterations to find wingbeat frequency")
    disp("Remaining error: " + err + ", Threshold: " + thresh)
    toc
end