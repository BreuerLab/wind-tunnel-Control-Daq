function [mod_filtered_data] = shiftPitchMoment(filtered_data, center_to_chord_posn, AoA)
    mod_filtered_data = filtered_data;

    % Shift pitch moment to new chord position that is closer to LE
    drag_force = filtered_data(1,:);
    lift_force = filtered_data(3,:);
    pitch_moment = filtered_data(5,:);
    
    % coordinate system is pos y up, pos x from LE to TE
    % These are measuring the magnitudes of distance between the center of
    % the sensor and the quarter chord position at glide (mid stroke). The
    % signs are taken care of in the shift pith moment equation
    horiz_shift_distance = center_to_chord_posn; % horiz distance between sensor and quarter chord
    vert_shift_distance = 0.02214; % vertical distance between top of load cell and center of mid stroke; same for all configs

    % [N = [c s [L
    % A]   -s c] D] this is just a global to local coordinate transform
    normal_force = lift_force*cosd(AoA) + drag_force*sind(AoA);
    axial_force = -lift_force*sind(AoA) + drag_force*cosd(AoA);
    
    % Shift pitch moment
    % signs are taken care of because the sensor is down (negative y) and
    % down the chord (positive x) from quarter chord (where
    % pitch_moment_shifted)
    pitch_moment_shifted = pitch_moment - (normal_force * horiz_shift_distance)...
        - (axial_force * vert_shift_distance);

    % pitch_moment_shifted = pitch_moment + normal_force * horiz_shift_distance; 
    % Above form said that horiz-shift_distance was negative. I am taking
    % care of signs in the equation only
    mod_filtered_data(5,:) = pitch_moment_shifted;
end