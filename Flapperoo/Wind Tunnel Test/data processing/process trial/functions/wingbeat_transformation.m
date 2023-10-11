function [wingbeat_forces, frames, wingbeat_avg_forces, wingbeat_SD_forces, wingbeat_rmse_forces, wingbeat_max_forces, wingbeat_min_forces, wingbeat_COP] = wingbeat_transformation(num_wingbeats, results)

frames_per_beat = length(results) / num_wingbeats;

wingbeat_forces = zeros(num_wingbeats, round(frames_per_beat), 6);
for j = 1:num_wingbeats
    for k = 1:round(frames_per_beat)
        wingbeat_forces(j,k,:) = results(k + round(frames_per_beat*(j-1)), :);
    end
end

frames = linspace(0, 1, round(frames_per_beat))';

wingbeat_avg_forces = zeros(round(frames_per_beat), 6);
wingbeat_SD_forces = zeros(round(frames_per_beat), 6);
wingbeat_rmse_forces = zeros(round(frames_per_beat), 6);
wingbeat_max_forces = zeros(round(frames_per_beat), 6);
wingbeat_min_forces = zeros(round(frames_per_beat), 6);
wingbeat_COP = zeros(round(frames_per_beat), 1);
for k = 1:round(frames_per_beat)
    for m = 1:6
        wingbeat_avg_forces(k,m) = mean(wingbeat_forces(:,k,m));
        wingbeat_SD_forces(k,m) = std(wingbeat_forces(:,k,m));
        wingbeat_rmse_forces(k,m) = rms(wingbeat_forces(:,k,m) - wingbeat_avg_forces(k,m));
        wingbeat_max_forces(k,m) = max(wingbeat_forces(:,k,m));
        wingbeat_min_forces(k,m) = min(wingbeat_forces(:,k,m));
    end
    wingbeat_COP(k) = mean(wingbeat_forces(:,k,5) ./ wingbeat_forces(:,k,3));
end

end