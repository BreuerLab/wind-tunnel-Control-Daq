function zeroWings(galil, dmc_motion_filename, dmc_stop_filename, flapper_obj, cal_matrix, case_name)
    tic
    case_name = case_name + "_zeroWings_";
    des_pos = 0;
    OF = 0.18;
    wait_time = 0.2;
    cur_pos = checkPos(flapper_obj, cal_matrix, case_name + "1");

    idx = 2;
    thresh = 0.5;
    while (err > thresh)
        moveWings(OF, wait_time, galil, dmc_motion_filename, dmc_stop_filename)
        cur_pos = checkPos(flapper_obj, cal_matrix, case_name + string(idx));
        err = abs(des_pos - cur_pos);

        idx = idx + 1;
    end
    disp("Loop complete, took " + idx + " iterations to find zero")
    disp("Remaining error: " + err + ", Threshold: " + thresh)
    toc
end