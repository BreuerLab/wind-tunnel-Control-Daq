function phi = calimero_mechanism(theta, d, r)
    % Wing angle phi from motor angle theta, positive with the wing above
    % horizontal. theta = 0 is the encoder zero (start of a trial), where
    % the wing is at midstroke moving up. The quick-return geometry gives
    % a short upstroke (~39% of the cycle for the 20 deg crank) and a long
    % downstroke (~61%) centred at t/T = 0.5; extremes at cos(theta) = r/d.
    %
    % This is the original expression -atan(r sin / (d + r cos)) with
    % theta offset by pi: encoder zero has the crank pin on the opposite
    % side from what that form assumed. (Before 10/22/26 the wing was
    % moving down at theta = 0, so stored phase_avg_wing_pos / wing_speed
    % / wing_acc are shifted by half a motor revolution.)
    phi = atan((r*sin(theta)) ./ (d - r*cos(theta)));
end
