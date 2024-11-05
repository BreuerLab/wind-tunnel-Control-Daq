function [lift_slope, pitch_slope] = getGlideSlopes(lim_AoA_sel, lim_avg_forces)
    lim_AoA_sel = deg2rad(lim_AoA_sel);

    freq_ind = 1; % corresponds to gliding case
    lift_force = lim_avg_forces(3,:,freq_ind);
    pitch_force = lim_avg_forces(5,:,freq_ind);

    x = [ones(size(lim_AoA_sel')), lim_AoA_sel'];
    y = lift_force';
    b_l = x\y;
    model_lift = x*b_l;
    lift_slope = b_l(2);
    % alpha_zero_l = - b_l(1) / b_l(2);
    % Rsq = 1 - sum((y - model).^2)/sum((y - mean(y)).^2);
    % SE_slope = (sum((y - model).^2) / (sum((lim_AoA_sel - mean(lim_AoA_sel)).^2)*(length(lim_AoA_sel) - 2)) ).^(1/2);
    % x_int = - b(1) / b(2);

    x = [ones(size(lim_AoA_sel')), lim_AoA_sel'];
    y = pitch_force';
    b_p = x\y;
    model_pitch = x*b_p;
    pitch_slope = b_p(2);
    % alpha_zero_p = - b_p(1) / b_p(2);

    plot_bool = false;
    if (plot_bool)
        figure
        hold on
        s = scatter(lim_AoA_sel, lift_force, 25, "filled");
        s.DisplayName = "Data";
        p = plot(lim_AoA_sel, model_lift);
        p.DisplayName = "y = " + round(b_l(2),3) + "x + " + round(b_l(1),3);
        hold off
        title("Lift Force")
        legend()

        figure
        hold on
        s = scatter(lim_AoA_sel, pitch_force, 25, "filled");
        s.DisplayName = "Data";
        p = plot(lim_AoA_sel, model_pitch);
        p.DisplayName = "y = " + round(b_p(2),3) + "x + " + round(b_p(1),3);
        hold off
        title("Pitch Moment")
        legend()
    end
end