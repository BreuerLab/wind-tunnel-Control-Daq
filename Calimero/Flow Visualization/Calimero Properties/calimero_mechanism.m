function phi = calimero_mechanism(theta, d, r)
    % Wing angle phi from motor angle theta (forward rotation), positive
    % with the wing above horizontal. phi rises through 0 at theta = 0, so
    % t = 0 is mid-upstroke and the downstroke is centred near t/T = 0.5.
    % Matches phi_eqt_F in kinematics/Calimero_kinematics.m. (Until
    % 10/22/26 this had a leading minus sign, which inverted the stored
    % phase_avg_wing_pos / wing_speed / wing_acc.)
    phi = atan((r*sin(theta)) ./ (d + r*cos(theta)));
end
