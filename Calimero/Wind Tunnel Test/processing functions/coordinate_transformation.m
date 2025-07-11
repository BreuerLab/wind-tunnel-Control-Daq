% Author: Ronan Gissler
% Last updated: July 2025

% What's the reasoning behind the rotation process:
% The pitch angle is adjusted via the MPS system causing the robot's
% reference frame to change relative to the wind tunnel reference frame

% Inputs:
% results - (n x 6) force transducer data
% pitch - pitch angle set by MPS system

% Returns:
% results_lab - (n x 6) rotated force transducer data
function results_lab = coordinate_transformation(results, pitch_d)
    pitch = deg2rad(-pitch_d);
    yaw_d = 180; % At 0 pitch angle, x- rotated 180 degrees from downstream
    yaw = deg2rad(yaw_d);

    dcm_F = angle2dcm(yaw, pitch, 0,'ZYX');
    dcm_M = angle2dcm(yaw, 0, 0, 'ZYX');
    
    F_lab = (dcm_F * results(1:3, :));
    T_lab = (dcm_M * results(4:6, :));
    results_lab = [F_lab; T_lab];
end