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
    % COP calculation will blow up when lift is zero
    wingbeat_COP(k) = mean(wingbeat_forces(:,k,5) ./ wingbeat_forces(:,k,3));
end

end