% To verify this function is transforming the data as expected check
% that as the AoA increases only the Z and Y force axes are affected.
function results_lab = coordinate_transformation(results, pitch)
    yaw = 205; % x- rotated 25 degrees from downstream
    roll = 0;
    
    Eulerangle_deg = [yaw, pitch, roll];
    Eulerangle = deg2rad(Eulerangle_deg);
    
    dcm_F = angle2dcm(Eulerangle(1),Eulerangle(2),Eulerangle(3),'ZYX');
    dcm_M = angle2dcm(Eulerangle(1),0,Eulerangle(3),'ZYX');
    F_lab = (dcm_F * results(:, 1:3)')';
    T_lab = (dcm_M * results(:, 4:6)')';
    results_lab = [F_lab, T_lab];
end