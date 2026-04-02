function [x, y, z, u, v, w, Utot, vortX, vortY, vortZ, vortTot, uncU, uncV, uncW, uncTot] = ...
    import_STB_data(file_path, nondim_bool, U, L, sel_frames, RPCA_bool)
D = loadpiv(file_path,"extractAllVariables","frameSelect",sel_frames); % "Validate", minCorrelationValue

if RPCA_bool
% RPCA filtering for velocities only near plane of interest
% 1. Filter uRaw
origSize = [size(D.u,1), size(D.u,2), 3, size(D.u,4)];
X_u = reshape(D.u(:,:,3:5,:), [], size(D.u, 4)); 
[L_u, ~] = RPCA(X_u);
D.u(:,:,3:5,:) = reshape(L_u, origSize);
% disp("u filtering complete")

% 2. Filter vRaw
X_v = reshape(D.v(:,:,3:5,:), [], size(D.v, 4)); 
[L_v, ~] = RPCA(X_v);
D.v(:,:,3:5,:) = reshape(L_v, origSize);
% disp("v filtering complete")

% 3. Filter wRaw
X_w = reshape(D.w(:,:,3:5,:), [], size(D.w, 4)); 
[L_w, ~] = RPCA(X_w);
D.w(:,:,3:5,:) = reshape(L_w, origSize);

disp("RPCA complete, calculating vorticity...")
for i = 1:size(D.u, 4)
[D.vortX(:,:,:,i), D.vortY(:,:,:,i), D.vortZ(:,:,:,i)] = ...
    calculateVorticity(D.x, D.y, D.z, D.u(:,:,:,i), D.v(:,:,:,i), D.w(:,:,:,i));
end
end

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
    z_full = D.z/L;
    uncU_full = D.uncU/U;
    uncV_full = D.uncV/U;
    uncW_full = D.uncW/U;
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
    uncU_full = D.uncU;
    uncV_full = D.uncV;
    uncW_full = D.uncW;
end

% uncTot = (uncU.^2 + uncV.^2 + uncW.^2).^(1/2);
% corr = D.corr;

trim_bool = false;
if trim_bool
% Trimming data down
ybounds = [-2.5 2.5]; % roughly -0.15 to 0.15 meters
% ybounds = [-2.86 2.86]; % roughly -0.2 to 0.2 meters
zbounds = [-2.3 2.45]; % roughly -0.2 to 0.2 meters
% ybounds = [-2 2]; % roughly -0.2 to 0.2 meters

y_idx = find(y_full(1,:,1) > ybounds(1) & y_full(1,:,1) < ybounds(2));  % columns
z_idx = find(z_full(1,1,:) > zbounds(1) & z_full(1,1,:) < zbounds(2));  % rows

x = x_full(:,y_idx,z_idx);
y = y_full(:,y_idx,z_idx);
z = z_full(:,y_idx,z_idx);
u = u_full(:,y_idx,z_idx,:);
v = v_full(:,y_idx,z_idx,:);
w = w_full(:,y_idx,z_idx,:);
vortZ = vort_z_full(:,y_idx,z_idx,:);
vortX = vort_x_full(:,y_idx,z_idx,:);
vortY = vort_y_full(:,y_idx,z_idx,:);
uncU = uncU_full(:,y_idx,z_idx,:);
uncV = uncV_full(:,y_idx,z_idx,:);
uncW = uncW_full(:,y_idx,z_idx,:);
% corr = corr(y_idx, x_idx,:);
else
x = x_full;
y = y_full;
z = z_full;
u = u_full;
v = v_full;
w = w_full;
vortZ = vort_z_full;
vortX = vort_x_full;
vortY = vort_y_full;
uncU = uncU_full;
uncV = uncV_full;
uncW = uncW_full;
end

% Calculate totals using vector sum
Utot = (u.^2 + v.^2 + w.^2).^(1/2);
vortTot = (vortX.^2 + vortY.^2 + vortZ.^2).^(1/2);
uncTot = (uncU.^2 + uncV.^2 + uncW.^2).^(1/2);

fin_W = round((max(x,[],"all") - min(x,[],"all")) * L * 100);
fin_L = round((max(y,[],"all") - min(y,[],"all")) * L * 100);

init_size = size(x_full);
fin_size = size(x);
% fprintf("Data trimmed from: (%d, %d) to (%d, %d)\n", ...
%              init_size(1), init_size(2), fin_size(1), fin_size(2));
% fprintf("Data trimmed from: (%d x %d cm) to (%d x %d cm)\n", ...
%              init_W, init_L, fin_W, fin_L);
end