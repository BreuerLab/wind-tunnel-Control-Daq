function [inertial_force] = get_inertial(ang_disp_cycle, lin_acc)
    wing_mass = 0.010; % kg
    inertial_force = 2*wing_mass*lin_acc(:,151).*cosd(ang_disp_cycle);
    COM_chord_pos = 0.15; % m
end

