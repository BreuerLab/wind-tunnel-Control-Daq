function modified_mean_results = shiftPitchMom(mean_results, AoA_sel, shift_distance)
    modified_mean_results = mean_results;
    normal_force = mean_results(3,:,:,:,:);
    for i = 1:length(AoA_sel)
        AoA = AoA_sel(i);
        lift_force = mean_results(3,AoA_sel == AoA,:,:,:);
        drag_force = mean_results(1,AoA_sel == AoA,:,:,:);
        normal_force(1,AoA_sel == AoA,:,:,:) = lift_force*cosd(AoA) + drag_force*sind(AoA);
    end
    shifted_pitch_moment = mean_results(5,:,:,:,:) - normal_force * shift_distance;
    modified_mean_results(5,:,:,:,:) = shifted_pitch_moment;
end