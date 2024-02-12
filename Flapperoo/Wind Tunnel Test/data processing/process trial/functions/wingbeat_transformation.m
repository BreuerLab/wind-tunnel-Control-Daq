% Author: Ronan Gissler
% Last updated: October 2023

% Inputs:
% num_wingbeats - number of wingbeats recorded during experiment
% results - (n x 6) raw force transducer data

% Returns:
% For simplicity, let's say p = num_wingbeats, m = frames_per_beat
% wingbeat_forces - (p x m x 6) forces and moments for each wingbeat (total
%                   of p wingbeats) and at each moment in time over that
%                   wingbeat (total of m moments where data was sample,
%                   i.e. a frame)
% frames - (m) an array of wingbeat timesteps
% wingbeat_avg_forces - (m x 6) forces produced on average over the course
%                       of a wingbeat
% wingbeat_SD_forces - (m x 6) standard deviation of forces across
%                      wingbeats over the course of a wingbeat
% wingbeat_rmse_forces - (m x 6) root mean square error of forces across
%                        wingbeats over the course of a wingbeat
% wingbeat_max_forces - (m x 6) max of forces over across wingbeats over
%                       the course of a wingbeat
% wingbeat_min_forces - (m x 6) min of forces over across wingbeats over
%                       the course of a wingbeat
% wingbeat_COP - (m x 1) average center of pressure location over the
%                course of a wingbeat
function [wingbeat_forces, frames, wingbeat_avg_forces, wingbeat_SD_forces,...
    wingbeat_rmse_forces, wingbeat_max_forces, wingbeat_min_forces, wingbeat_COP]...
    = wingbeat_transformation(num_wingbeats, results)

frames_per_beat = length(results) / num_wingbeats;

wingbeat_forces = zeros(6, num_wingbeats, round(frames_per_beat));
for j = 1:num_wingbeats
    for k = 1:round(frames_per_beat - 0.5)
        wingbeat_forces(:,j,k) = results(:, k + round(frames_per_beat*(j-1)));
    end
end

frames = linspace(0, 1, round(frames_per_beat));

wingbeat_avg_forces = zeros(6, round(frames_per_beat));
wingbeat_SD_forces = zeros(6, round(frames_per_beat));
wingbeat_rmse_forces = zeros(6, round(frames_per_beat));
wingbeat_max_forces = zeros(6, round(frames_per_beat));
wingbeat_min_forces = zeros(6, round(frames_per_beat));
wingbeat_COP = zeros(1, round(frames_per_beat));
for k = 1:round(frames_per_beat)
    for m = 1:6
        wingbeat_avg_forces(m,k) = mean(wingbeat_forces(m,:,k));
        wingbeat_SD_forces(m,k) = std(wingbeat_forces(m,:,k));
        wingbeat_rmse_forces(m,k) = rms(wingbeat_forces(m,:,k) - wingbeat_avg_forces(m,k));
        wingbeat_max_forces(m,k) = max(wingbeat_forces(m,:,k));
        wingbeat_min_forces(m,k) = min(wingbeat_forces(m,:,k));
    end
    % COP calculation will blow up when lift is zero
    wingbeat_COP(k) = mean(wingbeat_forces(5,:,k) ./ wingbeat_forces(3,:,k));
end

end