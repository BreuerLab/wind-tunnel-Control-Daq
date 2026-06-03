function time_avg_plots(S)
    % Only showing one plane, located at this index
    z_idx = 3;

    % --- Spanwise velocity ---
    figure;
    ax = gca;
    params.zero = 0;
    params.clims = [-0.1 0.1];
    params.cb_lab = "\boldmath$\frac{u}{U_{\infty}}$";
    params.title = "Spanwise velocity";
    PIV_plot(S.x(:,:,z_idx), S.y(:,:,z_idx), S.mean_u(:,:,z_idx), params, ax);
    
    % --- Vertical velocity ---
    figure;
    ax = gca;
    params.zero = 0;
    params.clims = [-0.1 0.1];
    params.cb_lab = "\boldmath$\frac{v}{U_{\infty}}$";
    params.title = "Vertical velocity";
    PIV_plot(S.x(:,:,z_idx), S.y(:,:,z_idx), S.mean_v(:,:,z_idx), params, ax);
    
    % --- Streamwise velocity ---
    figure;
    ax = gca;
    params.zero = -1;
    params.clims = [-1.1 -0.9];
    params.cb_lab = "\boldmath$\frac{w}{U_{\infty}}$";
    params.title = "Streamwise velocity";
    PIV_plot(S.x(:,:,z_idx), S.y(:,:,z_idx), S.mean_w(:,:,z_idx), params, ax);
    
    % --- Spanwise vorticity ---
    figure;
    ax = gca;
    params.zero = 0;
    params.clims = [-0.5 0.5];
    params.cb_lab = "\boldmath$\frac{\omega_x c}{U_{\infty}}$"; % Note: Consider if label should be omega?
    params.title = "Spanwise vorticity";
    PIV_plot(S.x(:,:,z_idx), S.y(:,:,z_idx), S.mean_vortX(:,:,z_idx), params, ax);
    
    % --- Vertical vorticity ---
    figure;
    ax = gca;
    params.zero = 0;
    params.clims = [-0.5 0.5];
    params.cb_lab = "\boldmath$\frac{\omega_y c}{U_{\infty}}$";
    params.title = "Vertical vorticity";
    PIV_plot(S.x(:,:,z_idx), S.y(:,:,z_idx), S.mean_vortY(:,:,z_idx), params, ax);
    
    % --- Streamwise vorticity ---
    figure;
    ax = gca;
    params.zero = 0;
    params.clims = [-1 1];
    params.cb_lab = "\boldmath$\frac{\omega_z c}{U_{\infty}}$";
    params.title = "Streamwise vorticity";
    PIV_plot(S.x(:,:,z_idx), S.y(:,:,z_idx), S.mean_vortZ(:,:,z_idx), params, ax);
end