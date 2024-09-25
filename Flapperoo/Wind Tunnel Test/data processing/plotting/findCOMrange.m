function [distance_vals_chord, slopes] = findCOMrange(mean_results, AoA_sel, plot_bool)
    [center_to_LE, chord, COM_span, wing_length, arm_length] = getWingMeasurements();
    
    % increment to shift position where moments are considered
    diff_shift = 0.0001;

    pitch_moment = mean_results(5,:,:,:,:);

    % get current slope of line based on regression
    x = [ones(size(AoA_sel')), AoA_sel'];
    y = pitch_moment';
    b = x\y;
    model = x*b;
    og_Rsq = 1 - sum((y - model).^2)/sum((y - mean(y)).^2);
    og_slope = b(2);

    NP_pos = findNP(mean_results, AoA_sel, false);

    shift_distance = NP_pos;
    max_shift_distance = 2*center_to_LE;
    % this used to just be center_to_LE which would go all the
    % way from the NP to the LE (0% chord)

    slopes = zeros(1,10000);

    iter = 0;
    while(shift_distance > -max_shift_distance)
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
    end

    slopes = slopes(slopes ~= 0);

    distance_vals = linspace(NP_pos, shift_distance, iter);
    [distance_vals_LE, distance_vals_chord] = posToChord(distance_vals);
    if plot_bool
        figure
        plot(distance_vals_chord, slopes)
        xlabel("Shift Distance (% Chord)")
        ylabel("dM/d\alpha Slope")
    end

end