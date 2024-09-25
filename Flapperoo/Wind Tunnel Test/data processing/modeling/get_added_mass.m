function [added_mass_force_vec] = get_added_mass(ang_disp, ang_acc, r, wing_length, AoA)
    lin_acc = deg2rad(ang_acc) * r;

    air_density = 1.2; % kg / m^3
    chord = 0.1; % m
    air_mass = air_density*chord^2; % kg / m

    added_mass_force_r = 2*air_mass*lin_acc.*cosd(ang_disp);

    added_mass_force = (sum(added_mass_force_r,2)*0.001) / wing_length;

    % assume inertial force acts at center of wings
    [center_to_LE, chord] = getWingMeasurements();
    shift_distance = -chord/2;

    drag_force = added_mass_force * sind(AoA);
    lift_force = added_mass_force * cosd(AoA);
    pitch_moment = added_mass_force * shift_distance;

    added_mass_force_vec = [drag_force, lift_force, pitch_moment];
end