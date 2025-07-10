% Inputs:
% theta - n x 1, motor angle in radians
% Outputs:
% Z - n x 1, wingtip vertical position in mm
function Z = get_wingtip_motion(theta)
    % Geometric parameters (adjust for your setup)
    r = 9.6;  % radius of cam (in mm)
    d = 20;   % horizontal distance between rotation center and slide axis (in mm)
    L = 200;  % total arm/slide length (in mm)
    
    % Compute vertical Z position (arm/slide projection) (of wingtip?)
    num = r * sin(theta);
    den = sqrt((r * cos(theta) - d).^2 + (r * sin(theta)).^2);
    Z = L * (num ./ den);  % position in mm (or consistent units)
end