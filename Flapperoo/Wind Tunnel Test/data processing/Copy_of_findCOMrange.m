% Assumptions: At zero shift, the curve already has a negative
% slope. Add code to find first shift distance where slope
% becomes negative
function [slopes, iter, low_pos, high_pos] = findCOMrange(mean_results, AoA_sel)
    [center_to_LE, chord] = getWingMeasurements();
    
    % increment to shift position where moments are considered
    diff_shift = 0.0001;

    pitch_moment = mean_results(5,:,:,:,:);

    x = [ones(size(AoA_sel')), AoA_sel'];
    y = pitch_moment';
    b = x\y;
    model = x*b;
    og_Rsq = 1 - sum((y - model).^2)/sum((y - mean(y)).^2);
    og_slope = b(2);

    % need code to first find shift distance where slope becomes
    % negative
    NP_pos = findNP(mean_results, AoA_sel, false);

    slope = og_slope;
    Rsq = og_Rsq;
    shift_distance = NP_pos;

    slopes = zeros(1,10000);
    Rsq_vals = zeros(1,10000);

    iter = 0;
    while(slope < 0 && shift_distance > -1 && Rsq > 0.9)
        shifted_results = shiftPitchMom(mean_results, AoA_sel, shift_distance);
        shifted_pitch_moment = shifted_results(5,:,:,:,:);
    
        x = [ones(size(AoA_sel')), AoA_sel'];
        y = shifted_pitch_moment';
        b = x\y;
        model = x*b;
        Rsq = 1 - sum((y - model).^2)/sum((y - mean(y)).^2);
        slope = b(2);

        shift_distance = shift_distance - diff_shift;
        iter = iter + 1;
        slopes(iter) = slope;
        % Rsq_vals(iter) = Rsq;
    end
    low_pos = shift_distance;
    avg_slope = sum(slopes) / iter;

    % Rsq_vals = Rsq_vals(Rsq_vals ~= 0);
    slopes = slopes(slopes ~= 0);

    % figure
    % scatter(1:1:iter, Rsq_vals)
    % xlabel("Iteration")
    % ylabel("R^2")

    % figure
    % hold on
    % scatter(AoA_sel, pitchMoment, 25, HandleVisibility="off");
    % plot(AoA_sel, model)

    cur_slope = og_slope;
    shift_distance = 0;
    Rsq = 1;
    while(cur_slope < 0 && shift_distance < 1  && Rsq > 0.9)
        prev_slope = cur_slope;
        shift_distance = shift_distance + diff_shift;

        shifted_results = shiftPitchMom(mean_results, AoA_sel, shift_distance);
        shifted_pitch_moment = shifted_results(5,:,:,:,:);
    
        x = [ones(size(AoA_sel')), AoA_sel'];
        y = shifted_pitch_moment';
        b = x\y;
        model = x*b;
        Rsq = 1 - sum((y - model).^2)/sum((y - mean(y)).^2);
        cur_slope = b(2);

        if (cur_slope < prev_slope)
            shift_distance = 1;
        end
    end
    high_pos = shift_distance;

    % scatter(AoA_sel, pitchMoment, 25, HandleVisibility="off");
    % plot(AoA_sel, model)
    % hold off

    low_pos_LE = low_pos - center_to_LE;
    percent_chord = -(low_pos_LE / chord) * 100;
    if (round(high_pos,4) == 1)
        disp("Stable COM positions include [" + low_pos + ", inf]")
        disp("[" + percent_chord + " %, inf]")
        disp("Average slope of " + avg_slope)
    end

end