function [inertial_force_vec] = get_inertial(ang_disp, ang_acc, r, COM_span, chord, AoA)
    lin_acc = deg2rad(ang_acc) * r;

    lin_acc_COM = lin_acc(:, round(r,3) == round(COM_span,3));

    wing_mass = 0.010; % kg
    inertial_force = 2*wing_mass*lin_acc_COM.*cosd(ang_disp);
    % positive sign because when you have mass accelerating
    % towards the force transducer, that will be read as a force
    % acting downwards (just like gravitational acceleration)
    % % negative sign because force on body acts opposite to
    % % acceleration of wing mass

    % assume inertial force acts at center of wings
    shift_distance = -chord/2;

    drag_force = inertial_force * sind(AoA);
    lift_force = inertial_force * cosd(AoA);
    pitch_moment = inertial_force * shift_distance;

    inertial_force_vec = [drag_force, lift_force, pitch_moment];
end