function [x, y, z, u, v, w, vortX, vortY, vortZ, uncTot] = import_STB_data(PIV_case_name, nondim_bool, U, L)
file_path = get_PIV_paths(PIV_case_name);
disp("Loading file: " + file_path)
D = loadpiv(file_path,"extractAllVariables"); % "Validate", minCorrelationValue

init_W = round((max(D.x,[],"all") - min(D.x,[],"all"))*100);
init_L = round((max(D.y,[],"all") - min(D.y,[],"all"))*100);

if nondim_bool % Non-dimensionalize variables
    u_full = D.u/U;
    v_full = D.v/U;
    w_full = D.w/U;
    vort_z_full = D.vortZ*(L/U);
    vort_x_full = D.vortX*(L/U);
    vort_y_full = D.vortY*(L/U);
    x_full = D.x/L;
    y_full = D.y/L;
    z_full = D.z; %D.z/L
    uncU = D.uncU/U;
    uncV = D.uncV/U;
    uncW = D.uncW/U;
else
    u_full = D.u;
    v_full = D.v;
    w_full = D.w;
    vort_z_full = D.vortZ;
    vort_x_full = D.vortX;
    vort_y_full = D.vortY;
    x_full = D.x;
    y_full = D.y;
    z_full = D.z;
    uncU = D.uncU;
    uncV = D.uncV;
    uncW = D.uncW;
end

uncTot = (uncU.^2 + uncV.^2 + uncW.^2).^(1/2);
% corr = D.corr;

% Trimming data down
xbounds = [-2.14 2.14]; % roughly -0.15 to 0.15 meters
% ybounds = [-2.86 2.86]; % roughly -0.2 to 0.2 meters
ybounds = [-2.48 2.48]; % roughly -0.2 to 0.2 meters

x_idx = find(x_full(1,:,1) > xbounds(1) & x_full(1,:,1) < xbounds(2));  % columns
y_idx = find(y_full(:,1,1) > ybounds(1) & y_full(:,1,1) < ybounds(2));  % rows

% swapped x and y indices
% Trim off first and last plane too
x = x_full(y_idx, x_idx,2:end-1);
y = y_full(y_idx, x_idx,2:end-1);
z = z_full(y_idx, x_idx,2:end-1);
u = u_full(y_idx, x_idx,2:end-1,:);
v = v_full(y_idx, x_idx,2:end-1,:);
w = w_full(y_idx, x_idx,2:end-1,:);
vortZ = vort_z_full(y_idx, x_idx,2:end-1,:);
vortX = vort_x_full(y_idx, x_idx,2:end-1,:);
vortY = vort_y_full(y_idx, x_idx,2:end-1,:);
uncTot = uncTot(y_idx, x_idx,2:end-1,:);
% corr = corr(y_idx, x_idx,:);

fin_W = round((max(x,[],"all") - min(x,[],"all")) * L * 100);
fin_L = round((max(y,[],"all") - min(y,[],"all")) * L * 100);

init_size = size(x_full);
fin_size = size(x);
fprintf("Data trimmed from: (%d, %d) to (%d, %d)\n", ...
             init_size(1), init_size(2), fin_size(1), fin_size(2));
fprintf("Data trimmed from: (%d x %d cm) to (%d x %d cm)\n", ...
             init_W, init_L, fin_W, fin_L);
end