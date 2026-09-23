function calc_secondary_vals_time(D, save_filepath_local)
tic

config.uField = 'mean_u';
config.vField = 'mean_v';
config.wField = 'mean_w';
config.UtotField = 'mean_Utot';
config.UtotDiffField = 'mean_Utot_diff';

config.vortXField = 'mean_vortX';
config.vortYField = 'mean_vortY';
config.vortZField = 'mean_vortZ';
config.vortTotField = 'mean_vortTot';

config.uncField = 'mean_uncTot';
config.numPField = 'mean_numP';
config.helField = 'mean_hel';

config.dudxField = 'mean_dudx';
config.dudyField = 'mean_dudy';
config.dudzField = 'mean_dudz';
config.dvdxField = 'mean_dvdx';
config.dvdyField = 'mean_dvdy';
config.dvdzField = 'mean_dvdz';
config.dwdxField = 'mean_dwdx';
config.dwdyField = 'mean_dwdy';
config.dwdzField = 'mean_dwdz';

config.speed = D.U;
config.length = D.L;
config.density = D.rho;

S = calc_secondary_vals_common(D, config);

% Save the entire structure
save_filename = D.PIV_case_name + "_time_avg_integral.mat";
save_path = fullfile(save_filepath_local, save_filename);
disp("Saving data to: " + save_path)
save(save_path, '-struct', 'S');

fprintf('Secondary file: Processing and saving data took %.4f seconds.\n', toc);
end