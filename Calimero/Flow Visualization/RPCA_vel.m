function [L, S] = RPCA_vel(x, y, z, u, v, w)

disp("RPCA beginning...")
tic

u = nanToMedian(u);
v = nanToMedian(v);
w = nanToMedian(w);

s_ind = 2;
e_ind = 4;
origSize = size(u(s_ind:e_ind,:,:,:));

% 1. Reshape and concatenate all three components vertically
% X will have dimensions [ (3 * Space), Time ]
X_all = [ reshape(u(s_ind:e_ind,:,:,:), [], size(u, 4)); ...
          reshape(v(s_ind:e_ind,:,:,:), [], size(v, 4)); ...
          reshape(w(s_ind:e_ind,:,:,:), [], size(w, 4))];

% 2. Run RPCA once on the combined matrix
% [L_all, S_all] = RPCA(X_all);
[L_all, S_all] = RPCA_TallSkinny_CPU(X_all);

% 3. Split the results back out
numElements = size(X_all, 1) / 3;
L_u = L_all(1:numElements, :);
L_v = L_all(numElements+1:2*numElements, :);
L_w = L_all(2*numElements+1:end, :);

S_u = S_all(1:numElements, :);
S_v = S_all(numElements+1:2*numElements, :);
S_w = S_all(2*numElements+1:end, :);

% 4. Reshape back to original dimensions
L_u_mat = reshape(L_u, origSize);
L_v_mat = reshape(L_v, origSize);
L_w_mat = reshape(L_w, origSize);

vortX = zeros(size(L_u_mat)); vortY = zeros(size(L_u_mat)); vortZ = zeros(size(L_u_mat));

% Calculate vorticity
for i = 1:size(L_u_mat, 4)
[vortX(:,:,:,i), vortY(:,:,:,i), vortZ(:,:,:,i)] = ...
    calculateVorticity(x, y, z, L_u_mat(:,:,:,i), L_v_mat(:,:,:,i), L_w_mat(:,:,:,i));
end

Utot = (L_u_mat.^2 + L_v_mat.^2 + L_w_mat.^2).^(1/2);
vortTot = (vortX.^2 + vortY.^2 + vortZ.^2).^(1/2);

L = {L_u_mat, L_v_mat, L_w_mat, Utot, vortX, vortY, vortZ, vortTot};

S_u_mat = reshape(S_u, origSize);
S_v_mat = reshape(S_v, origSize);
S_w_mat = reshape(S_w, origSize);
S = {S_u_mat, S_v_mat, S_w_mat};

toc
disp("RPCA complete, calculating vorticity...")
end