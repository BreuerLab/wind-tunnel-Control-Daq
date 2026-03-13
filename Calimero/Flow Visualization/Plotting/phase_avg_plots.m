function phase_avg_plots(S)
% movie plots, then 3D plots

folder = save_filepath + PIV_case_name;

if ~exist(folder, 'dir')
    mkdir(folder);
end

params.PIV_case_name = PIV_case_name;
params.save_filepath = save_filepath;
params.num_bins = num_bins;
% params.xlims = [-0.15 0.15];
% params.ylims = [-0.2 0.2];
params.xlims = [-2.14 2.14]; % roughly -0.15 to 0.15 meters
params.ylims = [-2.86 2.86]; % roughly -0.2 to 0.2 meters

z_ind = 3;
params.zero = 0;
params.title = "Spanwise vorticity - phase averaged";
params.folder = "vortX_avg";
params.clims = [-1 1];
make_movie(x(:,:,z_ind), y(:,:,z_ind), vortX_phase_avg(:,:,z_ind,:), params)

params.zero = 0;
params.title = "Vertical vorticity - phase averaged";
params.folder = "vortY_avg";
params.clims = [-1 1];
make_movie(x(:,:,z_ind), y(:,:,z_ind), vortY_phase_avg(:,:,z_ind,:), params)

params.zero = 0;
params.title = "Streamwise vorticity - phase averaged";
params.folder = "vortZ_avg";
params.clims = [-1 1];
make_movie(x(:,:,z_ind), y(:,:,z_ind), vortZ_phase_avg(:,:,z_ind,:), params)

params.zero = 0;
params.title = "Spanwise Q - phase averaged";
params.folder = "Qx_avg";
params.clims = [0.01 0.1];
make_movie(x(:,:,z_ind), y(:,:,z_ind), Qx(:,:,z_ind,:), params)

params.zero = 0;
params.title = "Vertical Q - phase averaged";
params.folder = "Qy_avg";
params.clims = [0.01 0.1];
make_movie(x(:,:,z_ind), y(:,:,z_ind), Qy(:,:,z_ind,:), params)

params.zero = 0;
params.title = "Streamwise Q - phase averaged";
params.folder = "Qz_avg";
params.clims = [0.01 0.1];
make_movie(x(:,:,z_ind), y(:,:,z_ind), Qz(:,:,z_ind,:), params)

params.zero = 0;
params.title = "Spanwise velocity - Average";
params.folder = "u_avg";
params.clims = [-0.2 0.2];
make_movie(x(:,:,z_ind), y(:,:,z_ind), u_phase_avg(:,:,z_ind,:), params)

params.zero = 0;
params.title = "Vertical velocity - Average";
params.folder = "v_avg";
params.clims = [-0.2 0.2];
make_movie(x(:,:,z_ind), y(:,:,z_ind), v_phase_avg(:,:,z_ind,:), params)

params.zero = -1;
params.title = "Streamwise velocity - Average";
params.folder = "w_avg";
params.clims = [-1.1 -0.9];
make_movie(x(:,:,z_ind), y(:,:,z_ind), w_phase_avg(:,:,z_ind,:), params)

%%
figure
params.clims = [-1 1];
params.zero = 0;
params.movie = false;
params.L = L;
params.shift = 0;
stack_vortices(x_tr, y_tr, vort_phase_avg_tr, Q_phase_avg_tr, wing_freq, params);

ax = gca;
ax.XAxisLocation = 'bottom';   % 'left' or 'right'
ax.YAxisLocation = 'right';   % 'left' or 'right'

% YZ view
view([0 0 1])   % camera along +X direction
% camup([0 1 0])  % keep Y vertical

exportgraphics(gcf, folder + "\phase_avg_stacked_XY.png", 'Resolution', 300);
end