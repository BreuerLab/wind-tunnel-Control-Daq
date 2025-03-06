% Inputs:
% sel_freq - wingbeat frequency, ex: "2 Hz", "2 Hz v2"
% AoA - angle of attack (in degrees), ex: 2
% wind_speed - wind speed (in m/s), ex: 4
% Outputs:
% All are 1 x n arrays where n represents many points over a
% wingbeat period
function [time, inertial_force, added_mass_force, aero_force] = ...
    getModel(path, flapper, sel_freq, AoA, wind_speed, lift_slope, pitch_slope, zero_lift_alpha, zero_pitch_alpha, AR, amp)

    wing_freq = str2double(extractBefore(sel_freq, " Hz"));

    [time, ang_disp, ang_vel, ang_acc] = get_kinematics(path, wing_freq, amp);

    [center_to_LE, chord, COM_span, ...
        wing_length, arm_length] = getWingMeasurements(flapper);

    full_length = wing_length + arm_length;
    r = arm_length:0.001:full_length;
    lin_vel = deg2rad(ang_vel) * r;
    lin_acc = deg2rad(ang_acc) * r;
    
    [eff_AoA, u_rel] = get_eff_wind(time, lin_vel, AoA, wind_speed);

    [inertial_force] = get_inertial(ang_disp, ang_acc, r, COM_span, chord, AoA);
    
    [C_L, C_D, C_N, C_M] = get_aero(ang_disp, eff_AoA, u_rel, wind_speed, wing_length,...
        lift_slope, pitch_slope, zero_lift_alpha, zero_pitch_alpha, AR);
    aero_force = [C_D, C_L, C_M];

    [added_mass_force] = get_added_mass(ang_disp, lin_acc, wing_length, chord, AoA);
end