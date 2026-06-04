function calc_secondary_vals_phase(D, F, turbine_bool, plot_bool, save_filepath_local)
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
    
    config.speed = speed;
    config.density = D.rho_act;
else
    config.speed = D.U;
    config.density = D.rho;
end

config.length = D.L;

S = calc_secondary_vals_common(D, config);

% copy over data from phase averaged kinematics and power
fnames = fieldnames(F);
for i = 1:numel(fnames)
    S.(fnames{i}) = F.(fnames{i});
end

% Save the entire structure
save_filename = D.PIV_case_name + "_phase_avg_integral.mat";
save_path = fullfile(save_filepath_local, save_filename);
disp("Saving data to: " + save_path)
save(save_path, '-struct', 'S');

fprintf('Secondary file: Processing and saving data took %.4f seconds.\n', toc);
end