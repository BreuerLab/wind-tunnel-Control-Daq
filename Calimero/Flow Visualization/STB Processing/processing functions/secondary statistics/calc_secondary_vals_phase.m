function calc_secondary_vals_phase(D, turbine_bool, plot_bool, save_filepath_local)
tic

config.uField = 'u_phase_avg';
config.vField = 'v_phase_avg';
config.wField = 'w_phase_avg';
config.UtotField = 'Utot_phase_avg';
config.UtotDiffField = 'Utot_diff_phase_avg';

config.vortXField = 'vortX_phase_avg';
config.vortYField = 'vortY_phase_avg';
config.vortZField = 'vortZ_phase_avg';
config.vortTotField = 'vortTot_phase_avg';

config.uncField = 'uncTot_phase_avg';
config.numPField = 'numP_phase_avg';
config.helField = 'hel_phase_avg';

config.dudxField = 'dudx_phase_avg';
config.dvdxField = 'dvdx_phase_avg';
config.dwdxField = 'dwdx_phase_avg';
config.dvdyField = 'dvdy_phase_avg';
config.dwdzField = 'dwdz_phase_avg';

if ~turbine_bool
num_bins = D.num_bins;
speed = D.U_act * D.U;
[~, ~, freq] = parse_name(D.PIV_case_name);
dt = 1 / (freq * num_bins);
x_conv = zeros(1, num_bins);
for k = 1:num_bins
    x_conv(k) =  speed * dt * (k - 1);
end

config.xConv = x_conv;
config.includeHelmDecomp = true;

config.wakeSpeed = speed;
config.wakeLength = D.L;
config.wakeAvgType = 1;
config.density = D.rho_act;
end

S = calc_secondary_vals_common(D, config);

% ----------------------------------------------------------------
% -------------- Calculate values from DAQ data ------------------
% ----------------------------------------------------------------
if ~turbine_bool
% Define the field names in the order they are returned by the function
fNames = {'norm_time_speed', 'phase_avg_pos', 'phase_std_pos', ...
          'phase_avg_speed', 'phase_std_speed',...
          'phase_avg_acc', 'phase_std_acc',...
          'phase_avg_wing_pos', 'phase_std_wing_pos',...
          'phase_avg_wing_speed', 'phase_std_wing_speed',...
          'phase_avg_wing_acc', 'phase_std_wing_acc',...
          'bin_count_speed', 'bin_std_speed',...
          'phase_avg_volt', 'phase_std_volt',...
          'phase_avg_cur', 'phase_std_cur'};

% Capture all outputs into a cell array
outputs = cell(1, numel(fNames));
[outputs{:}] = speed_phase_avg(D.PIV_case_name, plot_bool);

% Map cell array to struct fields
for i = 1:numel(fNames)
    S.(fNames{i}) = outputs{i};
end

S.phase_avg_speed_error = abs(S.phase_avg_speed - freq);
S.phase_avg_power = S.phase_avg_volt .* S.phase_avg_cur;
end

% Save the entire structure
save_filename = D.PIV_case_name + "_phase_avg_integral.mat";
save_path = fullfile(save_filepath_local, save_filename);
disp("Saving data to: " + save_path)
save(save_path, '-struct', 'S');

fprintf('Secondary file: Processing and saving data took %.4f seconds.\n', toc);
end