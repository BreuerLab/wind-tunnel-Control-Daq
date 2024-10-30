% Inputs:
% sel_freq - wingbeat frequency, ex: "2 Hz", "2 Hz v2"
% AoA - angle of attack (in degrees), ex: 2
% wind_speed - wind speed (in m/s), ex: 4
% Outputs:
% All are 1 x n arrays where n represents many points over a
% wingbeat period
function [time, inertial_force, added_mass_force, aero_force] = getModel(path, flapper, sel_freq, AoA, wind_speed)
    wing_freq = str2double(extractBefore(sel_freq, " Hz"));

    CAD_bool = true;
    [time, ang_disp, ang_vel, ang_acc] = get_kinematics(path, wing_freq, CAD_bool);

    [center_to_LE, chord, COM_span, ...
        wing_length, arm_length] = getWingMeasurements(flapper);

    full_length = wing_length + arm_length;
    r = arm_length:0.001:full_length;
    lin_vel = deg2rad(ang_vel) * r;
    lin_acc = deg2rad(ang_acc) * r;
    
    [eff_AoA, u_rel] = get_eff_wind(time, lin_vel, AoA, wind_speed);

    [inertial_force] = get_inertial(ang_disp, ang_acc, r, COM_span, chord, AoA);
    
    thinAirfoil = true;
    if (flapper == "Flapperoo")
        single_AR = 2.5;
    elseif (flapper == "MetaBird")
        single_AR = 2.5; % NEEDS UPDATING
    else
        error("Oops. Unknown flapper")
    end
    [C_L, C_D, C_N, C_M] = get_aero(ang_disp, eff_AoA, u_rel, wind_speed, wing_length, thinAirfoil, single_AR);
    aero_force = [C_D, C_L, C_M];

    [added_mass_force] = get_added_mass(ang_disp, ang_acc, r, wing_length, chord, AoA);
end