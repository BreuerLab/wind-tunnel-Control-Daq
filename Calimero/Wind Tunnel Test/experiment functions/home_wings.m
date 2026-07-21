function home_wings(flapper_obj, galil, case_name, dmc_home_filename, dmc_params)

    % move wings forward 2 revolutions to see a home pulse
    ticks_to_move = dmc_params.ticksPerRev*2;
    move_wings(galil, dmc_home_filename, dmc_params, ticks_to_move)

    % Collect data during move
    session_duration = 5;
    disp("Homing data collection has begun");
    results = flapper_obj.measure_force(case_name, session_duration);
    disp("Homing data has been gathered");
    beep2;

    hall_effect = results(:,10);
    tick_ctr = results(:,11);
    % Get position in ticks associated with the center of a home pulse
    [cur_pos, home_pos] = get_home_pos(hall_effect, tick_ctr);

    mod_cur_pos = mod(cur_pos,dmc_params.ticksPerRev) * dmc_params.OC_pulse_step;
    mod_home_pos = mod(home_pos,dmc_params.ticksPerRev) * dmc_params.OC_pulse_step;

    if mod_home_pos > mod_cur_pos
        ticks_to_move = mod_home_pos - mod_cur_pos;
    else
        ticks_to_move = mod_home_pos + (dmc_params.ticksPerRev - mod_cur_pos);
    end

    % move wings forward to that new home position
    move_wings(galil, dmc_home_filename, dmc_params, ticks_to_move)

end