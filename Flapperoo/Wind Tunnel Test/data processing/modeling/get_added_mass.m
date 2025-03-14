function [added_mass_force_vec] = get_added_mass(ang_disp, lin_acc, wing_length, chord, AoA)
    air_density = 1.2; % kg / m^3
    air_mass = air_density*(chord/2)^2; % kg / m

    added_mass_force_r = 2*air_mass*lin_acc.*cosd(ang_disp);

    added_mass_force = (sum(added_mass_force_r,2)*0.001) / wing_length;
    % a normal force

    % assume inertial force acts at center of wings
    shift_distance = -chord/2;

    drag_force = added_mass_force * sind(AoA);
    lift_force = added_mass_force * cosd(AoA);
    pitch_moment = added_mass_force * shift_distance;

    added_mass_force_vec = [drag_force, lift_force, pitch_moment];
end