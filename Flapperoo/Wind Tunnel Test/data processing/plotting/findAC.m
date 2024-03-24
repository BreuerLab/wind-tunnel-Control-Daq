function AC_pos = findAC(mean_results, AoA_sel)
    center_to_LE = 0.06335; % in meters, distance from center of force transducer to leading edge of wing
    chord = 0.10; % in meters

    AC_pos = 0;
    shift_distance = 0;
    cur_slope = -1;
    prev_slope = -2;
    max_iter = 10000;
    iter = 0;
    diff_shift = 0.00001;

    % initial regression to check which direction to shift in
    pitchMoment = mean_results(5,:,:,:,:);

    x = [ones(size(AoA_sel')), AoA_sel'];
    y = pitchMoment';
    b = x\y;
    model = x*b;
    Rsq = 1 - sum((y - model).^2)/sum((y - mean(y)).^2);
    cur_slope = b(2);

    if (cur_slope < 0)
        diff_shift = -diff_shift;
    end

    % keep adjusting COP position until slope falls within
    % certain bounds of zero as long as error is improving and
    % max number of iterations is not exceeded
    while(abs(cur_slope) > 0.0001 && abs(cur_slope) < abs(prev_slope) && iter < max_iter)
    prev_slope = cur_slope;
    shift_distance = shift_distance + diff_shift;

    shifted_results = shiftPitchMom(mean_results, AoA_sel, shift_distance);
    pitchMoment = shifted_results(5,:,:,:,:);

    x = [ones(size(AoA_sel')), AoA_sel'];
    y = pitchMoment';
    b = x\y;
    model = x*b;
    Rsq = 1 - sum((y - model).^2)/sum((y - mean(y)).^2);
    cur_slope = b(2);

    iter = iter + 1;
    end

    AC_pos = shift_distance;
    AC_pos_LE = AC_pos - center_to_LE;
    disp("Number of iterations " + iter)
    disp("Center of Pressure shifted " + AC_pos_LE + " meters from LE")
    if (AC_pos_LE < 0)
        percent_chord = -(AC_pos_LE / chord) * 100;
        disp("At the " + percent_chord + "% chord")
    end

    figure
    hold on
    scatter(AoA_sel, pitchMoment, 25, HandleVisibility="off");
    plot(AoA_sel, model)
    hold off
end