% Assumptions: mean_results has dimensions so that the COP is
% defined in meters
function [COP] = getCOP(avg_data, AoA_sel, center_to_LE, chord)
    drag_force = avg_data(1,:);
    lift_force = avg_data(3,:);
    pitch_moment = avg_data(5,:);

    normal_force = zeros(size(drag_force));
    for i = 1:length(AoA_sel)
        AoA = AoA_sel(i);
        normal_force(i) = lift_force(i)*cosd(AoA) + drag_force(i)*sind(AoA);
    end
    
    % Calculate COP
    COP = pitch_moment ./ normal_force;
    % % COP position (in meters) relative to load cell center

    COP = posToChord(-COP, center_to_LE, chord);

    % COP = - pitch_moment ./ normal_force;
    % [COP_LE, COP_chord] = posToChord(COP);
end