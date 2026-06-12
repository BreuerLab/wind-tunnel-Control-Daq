clear
close all

filepath = "Y:\Processed Results\phase_avg\flexible_20deg_6Hz_phase_avg.mat";

TRIM_Y_BOUNDS = [-2.26 2]; % roughly -0.15 to 0.15 m
TRIM_Z_BOUNDS = [-2.36 2.55]; % roughly -0.2 to 0.2 m

vars = {"u_phase_avg", "v_phase_avg", "w_phase_avg", "y", "z",...
        "num_bins", "U", "U_act"};

load(filepath, vars{:})

y = squeeze(y(3,:,:));
z = squeeze(z(3,:,:));

y_idx = find(y(:,1) > TRIM_Y_BOUNDS(1) & y(:,1) < TRIM_Y_BOUNDS(2));
z_idx = find(z(1,:) > TRIM_Z_BOUNDS(1) & z(1,:) < TRIM_Z_BOUNDS(2));

u_phase_avg = squeeze(u_phase_avg(3,y_idx,z_idx,:));
v_phase_avg = squeeze(v_phase_avg(3,y_idx,z_idx,:));
w_phase_avg = squeeze(w_phase_avg(3,y_idx,z_idx,:));
y = y(y_idx,z_idx);
z = z(y_idx,z_idx);

speed = U_act * U;
% [~, ~, freq] = parse_name(D.PIV_case_name);
freq = 6;
dt = 1 / (freq * num_bins);
x = zeros(1, num_bins);
for k = 1:num_bins
    x(k) =  speed * dt * (k - 1);
end