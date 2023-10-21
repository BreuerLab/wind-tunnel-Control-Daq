% To verify this function is transforming the data as expected check
% that as the AoA increases only the Z and X force axes are affected.
% F_y should be near zero throughout.

% Slope of F_x graph should be positive if x+ is pointing downstream

% Also when doing weight taring, slope of pitching moment graph should be
% positive based on the results I found when placing a mass on the x+ or x-
% side of the force transducer
function results_lab = coordinate_transformation(results, pitch)
    yaw = 205; % x- rotated 25 degrees from downstream
    roll = 0;
    
    Eulerangle_deg = [yaw, pitch, roll];
    Eulerangle = deg2rad(Eulerangle_deg);
%     dcm_F = angle2dcm(Eulerangle(3),Eulerangle(2),Eulerangle(1),'XYZ');
    dcm_F = angle2dcm(Eulerangle(1),Eulerangle(2),Eulerangle(3),'ZYX');
    dcm_M = angle2dcm(Eulerangle(3),Eulerangle(2),Eulerangle(1),'XYZ');
    dcm_M = angle2dcm(Eulerangle(3),0,Eulerangle(1),'XYZ');
    
   % Z-rotation * Y-rotation * X rotation, so X-rotation first, then
   % Y-rotation, then Z-rotation
%     dcm_comp = [cos(Eulerangle(1)),sin(Eulerangle(1)),0; -sin(Eulerangle(1)),cos(Eulerangle(1)),0; 0,0,1]*...
%         [cos(Eulerangle(2)),0,-sin(Eulerangle(2)); 0,1,0; sin(Eulerangle(2)),0,cos(Eulerangle(2));]*...
%         [1,0,0; 0,1,0; 0,0,1];    
    
    F_lab = (dcm_F * results(:, 1:3)')';
%     T_lab = (roty(-Eulerangle(2)) * dcm_M' * results(:, 4:6)')';
    T_lab = (dcm_M * results(:, 4:6)')';
    results_lab = [F_lab, T_lab];
end