function distFromZero = zeroWings(galil, dmc_motion_filename, dmc_stop_filename, flapper_obj, case_name, distFromZero, freq, OF)
    tic
    case_name = case_name + "_zeroWings_";
    des_pos = 0;
    session_duration = round((distFromZero / freq) + 0.001*(freq^2), 3) - 0.05;
    disp("Current distance from zero: " + distFromZero)

    idx = 0;
    thresh = 0.02;
    while (distFromZero > thresh && (1 - distFromZero) > thresh)
        k = 0.1;
        session_duration = session_duration + k*distFromZero;
        distFromZero = moveWings(OF, session_duration, galil, dmc_motion_filename, ...
            dmc_stop_filename, flapper_obj, case_name, distFromZero);

        disp("Current distance from zero: " + distFromZero)
        idx = idx + 1;
        pause(0.2)
    end
    disp("Loop complete, took " + idx + " iterations to find zero")
    disp("Remaining error: " + distFromZero + ", Threshold: " + thresh)
    toc
end