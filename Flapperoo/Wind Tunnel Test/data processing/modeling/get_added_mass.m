function [added_mass_force_vec, COP_span_AM] = get_added_mass(ang_disp, ang_vel, ang_acc, wing_length, chord, AoA, dr, r)
    air_density = 1.2; % kg / m^3
    % air_mass = air_density*(chord/2)^2; % kg / m
    air_mass = air_density * pi * (chord/2)^2; % kg / m
    % brennan added mass reference: https://authors.library.caltech.edu/records/6819e-vnh65

    ang_disp = deg2rad(ang_disp);
    ang_vel = deg2rad(ang_vel);
    ang_acc = deg2rad(ang_acc);
    % lin_acc = deg2rad(ang_acc) * r;

    % added_mass_force_r = 2*air_mass*lin_acc.*cosd(ang_disp);
    added_mass_force_r = 2 * air_mass * r .* (ang_acc .* cos(ang_disp) - ang_vel.^2 .* sin(ang_disp));

    % factor of 2 gets divided out so it doesn't matter
    COP_span_AM = sum(added_mass_force_r .* r, 2) ./ sum(added_mass_force_r, 2);

    % added_mass_force = (sum(added_mass_force_r,2)*dr) / wing_length;
    added_mass_force = trapz(dr, added_mass_force_r, 2);
    % Should I be dividing by wing_length
    % a normal force

    % assume inertial force acts at center of wings
    shift_distance = -chord/2;

    drag_force = added_mass_force * sind(AoA);
    lift_force = added_mass_force * cosd(AoA);
    pitch_moment = added_mass_force * shift_distance;

    added_mass_force_vec = [drag_force, lift_force, pitch_moment];
end