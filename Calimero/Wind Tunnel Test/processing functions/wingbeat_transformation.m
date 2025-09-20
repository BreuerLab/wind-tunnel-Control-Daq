% Author: Ronan Gissler
% Last updated: September 2025

% Inputs:
% num_wingbeats - number of wingbeats recorded during experiment
% results - (n x 6) raw force transducer data

% Returns:
% For simplicity, let's say p = num_wingbeats, m = frames_per_beat
% wingbeat_forces - (6 x p x m) forces and moments for each wingbeat (total
%                   of p wingbeats) and at each moment in time over that
%                   wingbeat (total of m moments where data was sample,
%                   i.e. a frame)
% frames - (m) an array of wingbeat timesteps
% wingbeat_avg_forces - (6 x m) forces produced on average over the course
%                       of a wingbeat
% wingbeat_SD_forces - (6 x m) standard deviation of forces across
%                      wingbeats over the course of a wingbeat
% wingbeat_rmse_forces - (6 x m) root mean square error of forces across
%                        wingbeats over the course of a wingbeat
% wingbeat_max_forces - (6 x m) max of forces over across wingbeats over
%                       the course of a wingbeat
% wingbeat_min_forces - (6 x m) min of forces over across wingbeats over
%                       the course of a wingbeat
% wingbeat_COP - (1 x m) average center of pressure location over the
%                course of a wingbeat
% cycle_avg_forces - (6 x p) average force produced for each
%                    wingbeat
function [wingbeat_forces, frames, wingbeat_avg_forces, wingbeat_SD_forces,...
    wingbeat_rmse_forces, wingbeat_max_forces, wingbeat_min_forces, wingbeat_COP,...
    cycle_avg_forces]...
    = wingbeat_transformation(num_wingbeats, forces, enc_pulse, AoA, rate)

numAxes = 8;

frames_per_beat = round(length(forces) / num_wingbeats);

long_rises_orig_idx = get_idx_wingbeats(enc_pulse, rate);
% only 180 since no long pulse included at end

wingbeat_forces = zeros(numAxes, num_wingbeats, frames_per_beat);
cycle_avg_forces = zeros(numAxes, num_wingbeats);
% upstroke_avg_forces = zeros(6, num_wingbeats);
% downstroke_avg_forces = zeros(6, num_wingbeats);
cur_idx = 1;
for j = 1:num_wingbeats
    if (j == num_wingbeats)
        cur_wingbeat = forces(:, cur_idx:end);
        cur_wingbeat_resampled = resample(cur_wingbeat.', frames_per_beat, length(cur_wingbeat)).';
        wingbeat_forces(:,j,:) = cur_wingbeat_resampled;
    else
        end_idx = long_rises_orig_idx(j+1);
        cur_wingbeat = forces(:, cur_idx:end_idx);
        cur_wingbeat_resampled = resample(cur_wingbeat.', frames_per_beat, length(cur_wingbeat)).';
        wingbeat_forces(:,j,:) = cur_wingbeat_resampled;
    end
    cycle_avg_forces(:,j) = mean(wingbeat_forces(:,j,:), 3);
    % downstroke_avg_forces(:,j) = mean(wingbeat_forces(:,j,1:downstroke_length), 3);
    % upstroke_avg_forces(:,j) = mean(wingbeat_forces(:,j,downstroke_length+1:end), 3);

    cur_idx = end_idx;
end

frames = linspace(0, 1, frames_per_beat);

wingbeat_avg_forces = zeros(numAxes, frames_per_beat);
wingbeat_SD_forces = zeros(numAxes, frames_per_beat);
wingbeat_rmse_forces = zeros(numAxes, frames_per_beat);
wingbeat_max_forces = zeros(numAxes, frames_per_beat);
wingbeat_min_forces = zeros(numAxes, frames_per_beat);
wingbeat_COP = zeros(1, frames_per_beat);
for k = 1:frames_per_beat
    for m = 1:numAxes
        wingbeat_avg_forces(m,k) = mean(wingbeat_forces(m,:,k));
        wingbeat_SD_forces(m,k) = std(wingbeat_forces(m,:,k));
        wingbeat_rmse_forces(m,k) = rms(wingbeat_forces(m,:,k) - wingbeat_avg_forces(m,k));
        wingbeat_max_forces(m,k) = max(wingbeat_forces(m,:,k));
        wingbeat_min_forces(m,k) = min(wingbeat_forces(m,:,k));
    end
    % COP calculation will blow up when normal force is zero
    % Changed this from dividing by lift to dividing by normal
    % force on 09/03/2024
    lift = wingbeat_forces(3,:,k);
    drag = wingbeat_forces(1,:,k);
    norm_force = lift * cosd(AoA) + drag * sind(AoA);
    wingbeat_COP(k) = mean(wingbeat_forces(5,:,k) ./ norm_force);
end

end