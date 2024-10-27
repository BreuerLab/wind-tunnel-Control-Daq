function [mod_filtered_data] = shiftPitchMoment(filtered_data, center_to_LE, AoA)
    mod_filtered_data = filtered_data;

    % Shift pitch moment to LE
    drag_force = filtered_data(1,:);
    lift_force = filtered_data(3,:);
    pitch_moment = filtered_data(5,:);
    
    normal_force = lift_force*cosd(AoA) + drag_force*sind(AoA);
    
    shift_distance = -center_to_LE;
    
    % Shift pitch moment
    pitch_moment_LE = pitch_moment + normal_force * shift_distance;
    mod_filtered_data(5,:) = pitch_moment_LE;
end

