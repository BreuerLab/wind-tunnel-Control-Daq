% Assumptions: mean_results has dimensions so that the COP is
% defined in meters
function [mod_avg_data] = shiftPitchMom(avg_data, shift_distance, AoA_sel)
    mod_avg_data = avg_data;

    % Shift pitch moment to LE
    drag_force = avg_data(1,:);
    lift_force = avg_data(3,:);
    pitch_moment = avg_data(5,:);

    normal_force = zeros(size(drag_force));
    for i = 1:length(AoA_sel)
        AoA = AoA_sel(i);
        normal_force(i) = lift_force(i)*cosd(AoA) + drag_force(i)*sind(AoA);
    end
    
    % Shift pitch moment
    pitch_moment_LE = pitch_moment + normal_force * shift_distance;
    mod_avg_data(5,:) = pitch_moment_LE;
end

    % modified_mean_results = mean_results;
    % normal_force = mean_results(3,:,:,:,:);
    % pitch_moment = mean_results(5,:,:,:,:);
    % 
    % % Calculate normal force from lift and drag forces for each
    % % angle of attack
    % for i = 1:length(AoA_sel)
    %     AoA = AoA_sel(i);
    %     lift_force = mean_results(3,AoA_sel == AoA,:,:,:);
    %     drag_force = mean_results(1,AoA_sel == AoA,:,:,:);
    %     normal_force(1,AoA_sel == AoA,:,:,:) = ...
    %         lift_force*cosd(AoA) + drag_force*sind(AoA);
    % end
    % % COP position (in meters) relative to load cell center
    % COP = - pitch_moment ./ normal_force;
    % [COP_LE, COP_chord] = posToChord(COP);
    % 
    % % Shift pitch moment
    % shifted_pitch_moment = pitch_moment + normal_force * shift_distance;
    % modified_mean_results(5,:,:,:,:) = shifted_pitch_moment;