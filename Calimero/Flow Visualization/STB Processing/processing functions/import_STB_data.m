function [x, y, z, u, v, w, Utot, vortX, vortY, vortZ, vortTot, uncU, uncV, uncW, uncTot, hel, num_particles,...
    dudx, dudy, dudz, dvdx, dvdy, dvdz, dwdx, dwdy, dwdz, Utot_diff] = ...
    import_STB_data(file_path, nondim_bool, U, L, sel_frames, RPCA_bool)

D = loadpiv(file_path,"extractAllVariables","frameSelect",sel_frames); % "Validate", minCorrelationValue

if RPCA_bool
% % RPCA filtering for velocities only near plane of interest
% % 1. Filter uRaw
% origSize = [size(D.u,1), size(D.u,2), 3, size(D.u,4)];
% X_u = reshape(D.u(:,:,3:5,:), [], size(D.u, 4)); 
% [L_u, ~] = RPCA(X_u);
% D.u(:,:,3:5,:) = reshape(L_u, origSize);
% % disp("u filtering complete")
% 
% % 2. Filter vRaw
% X_v = reshape(D.v(:,:,3:5,:), [], size(D.v, 4)); 
% [L_v, ~] = RPCA(X_v);
% D.v(:,:,3:5,:) = reshape(L_v, origSize);
% % disp("v filtering complete")
% 
% % 3. Filter wRaw
% X_w = reshape(D.w(:,:,3:5,:), [], size(D.w, 4)); 
% [L_w, ~] = RPCA(X_w);
% D.w(:,:,3:5,:) = reshape(L_w, origSize);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
tic
s_ind = 2;
e_ind = 4;
origSize = size(D.u(s_ind:e_ind,:,:,:));

% 1. Reshape and concatenate all three components vertically
% X will have dimensions [ (3 * Space), Time ]
X_all = [ reshape(D.u(s_ind:e_ind,:,:,:), [], size(D.u, 4)); ...
          reshape(D.v(s_ind:e_ind,:,:,:), [], size(D.v, 4)); ...
          reshape(D.w(s_ind:e_ind,:,:,:), [], size(D.w, 4))];

% 2. Run RPCA once on the combined matrix
[L_all, ~] = RPCA(X_all);

% 3. Split the results back out
numElements = size(X_all, 1) / 3;
L_u = L_all(1:numElements, :);
L_v = L_all(numElements+1:2*numElements, :);
L_w = L_all(2*numElements+1:end, :);

% 4. Reshape back to original dimensions
D.u(s_ind:e_ind,:,:,:) = reshape(L_u, origSize);
D.v(s_ind:e_ind,:,:,:) = reshape(L_v, origSize);
D.w(s_ind:e_ind,:,:,:) = reshape(L_w, origSize);

toc
disp("RPCA complete, calculating vorticity...")
for i = 1:size(D.u, 4)
[D.vortX(:,:,:,i), D.vortY(:,:,:,i), D.vortZ(:,:,:,i)] = ...
    calculateVorticity(D.x, D.y, D.z, D.u(:,:,:,i), D.v(:,:,:,i), D.w(:,:,:,i));
end
end

if nondim_bool % Non-dimensionalize variables
    u = D.u/U;
    u_diff = u + 1;
    v = D.v/U;
    w = D.w/U;
    vortZ = D.vortZ*(L/U);
    vortX = D.vortX*(L/U);
    vortY = D.vortY*(L/U);
    x = D.x/L;
    y = D.y/L;
    z = D.z/L;
    uncU = D.uncU/U;
    uncV = D.uncV/U;
    uncW = D.uncW/U;
    dudx = D.dudx*(L/U);
    dudy = D.dudy*(L/U);
    dudz = D.dudz*(L/U);
    dvdx = D.dvdx*(L/U);
    dvdy = D.dvdy*(L/U);
    dvdz = D.dvdz*(L/U);
    dwdx = D.dwdx*(L/U);
    dwdy = D.dwdy*(L/U);
    dwdz = D.dwdz*(L/U);
else
    u = D.u;
    u_diff = u + U;
    v = D.v;
    w = D.w;
    vortZ = D.vortZ;
    vortX = D.vortX;
    vortY = D.vortY;
    x = D.x;
    y = D.y;
    z = D.z;
    uncU = D.uncU;
    uncV = D.uncV;
    uncW = D.uncW;
    dudx = D.dudx;
    dudy = D.dudy;
    dudz = D.dudz;
    dvdx = D.dvdx;
    dvdy = D.dvdy;
    dvdz = D.dvdz;
    dwdx = D.dwdx;
    dwdy = D.dwdy;
    dwdz = D.dwdz;
end

num_particles = D.numP;

% Total vel calculated without NaNs
u_tmp = nanToMedian(u);
u_diff_tmp = nanToMedian(u_diff);
v_tmp = nanToMedian(v);
w_tmp = nanToMedian(w);

% Calculate totals using vector sum
Utot = (u_tmp.^2 + v_tmp.^2 + w_tmp.^2).^(1/2);
Utot_diff = (u_diff_tmp.^2 + v_tmp.^2 + w_tmp.^2).^(1/2);
vortTot = (vortX.^2 + vortY.^2 + vortZ.^2).^(1/2);
uncTot = (uncU.^2 + uncV.^2 + uncW.^2).^(1/2);

hel = (u .* vortX) + (v .* vortY) + (w .* vortZ);
hel = hel ./ (vortTot .* Utot);
end