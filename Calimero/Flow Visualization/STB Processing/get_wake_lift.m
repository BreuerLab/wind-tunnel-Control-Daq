function [lift, drag] = get_wake_lift(U, L, y, z, S, avg_type, vort_bool, y_cen, z_cen, density)
    dy = abs(y(1,2,1) - y(1,1,1)) * L;
    dz = abs(z(1,1,2) - z(1,1,1)) * L;
    dA = dy*dz;

    trim_bool = true;
    if trim_bool
        ybounds = [-2.7 2.45]; % roughly -0.15 to 0.15 meters
        zbounds = [-2.36 2.55]; % roughly -0.2 to 0.2 meters
        
        y_idx = find(y(1,:,1) > ybounds(1) & y(1,:,1) < ybounds(2));  % columns
        z_idx = find(z(1,1,:) > zbounds(1) & z(1,1,:) < zbounds(2));  % rows
        
        y = y(:, y_idx, z_idx);
        z = z(:, y_idx, z_idx);

    switch avg_type
        case 0
            u = squeeze(S.mean_u(:, y_idx, z_idx)) * U;
            w = squeeze(S.mean_w(:, y_idx, z_idx)) * U;
            if vort_bool
            vortX = squeeze(S.mean_vortX(:, y_idx, z_idx)) * (U/L);
            vortY = squeeze(S.mean_vortY(:, y_idx, z_idx)) * (U/L);
            vortZ = squeeze(S.mean_vortZ(:, y_idx, z_idx)) * (U/L);
            end
        case 1
            u = squeeze(S.u_phase_avg(:, y_idx, z_idx, :)) * U;
            w = squeeze(S.w_phase_avg(:, y_idx, z_idx, :)) * U;
            if vort_bool
            vortX = squeeze(S.vortX_phase_avg(:, y_idx, z_idx, :)) * (U/L);
            vortY = squeeze(S.vortY_phase_avg(:, y_idx, z_idx, :)) * (U/L);
            vortZ = squeeze(S.vortZ_phase_avg(:, y_idx, z_idx, :)) * (U/L);
            end
    end
    end

    % First trim data about center point
    y_idx = find(y(1,:,1) > y_cen);  % columns

    z = z - z_cen;

    x_ind = 3;

    % Make values dimensional
    y = squeeze(y(x_ind, y_idx, :)) * L;
    z = squeeze(z(x_ind, y_idx, :)) * L;

    % shift axis so that min point is now considered as origin
    y = y - min(y, [], "all");

    switch avg_type
        case 0
            u = squeeze(u(x_ind, y_idx, :));
            w = squeeze(w(x_ind, y_idx, :));
            if vort_bool
            vortX = squeeze(vortX(x_ind, y_idx, :));
            vortY = squeeze(vortY(x_ind, y_idx, :));
            vortZ = squeeze(vortZ(x_ind, y_idx, :));
            end
        case 1
            u = squeeze(u(x_ind, y_idx, :, :));
            w = squeeze(w(x_ind, y_idx, :, :));
            if vort_bool
            vortX = squeeze(vortX(x_ind, y_idx, :, :));
            vortY = squeeze(vortY(x_ind, y_idx, :, :));
            vortZ = squeeze(vortZ(x_ind, y_idx, :, :));
            end
    end

    % in my reference frame right wing produces positive vorticity, but
    % in their reference frame, it produces negative vorticity

    % spanwise coordinate (x here) increasing outboards agrees with
    % their ref. frame

    % vertical velocity is positive in the downwards direction,
    % opposite my reference frame

    % streamwise velocity is positive in the forward direction, same as
    % mine

    % THESE CALCULATIONS ONLY WORK FOR AVERAGE LIFT, time varying lift
    % should account for contribution from d/dt term in N-S

    %% Calculate lift
    if vort_bool
        % term1 = -U * dA * x .* -vortZ; 
        % term2 = (w + U) .* -v .* dA; % effectively zero
        term1 = -U * y .* -vortX; 
        term2 = (u + U) .* -w; % effectively zero
        lift_mat = term1 - term2;
    
        lift_vec = trapz(y(:,1), lift_mat, 1);
        lift = 2 * density * trapz(z(1,:), lift_vec, 2);
        lift = squeeze(lift);
    else
        lift_mat_full = -(u .* -w);

        lift_vec_full = trapz(y(:,1), lift_mat_full, 1);
        lift = 2 * density * trapz(z(1,:), lift_vec_full, 2);
        lift = squeeze(lift);
    end

    %% Calculate drag
    if vort_bool
        % is y = 0 properly centered at body axis?
        term1 = U^2;
        % term2 = U * -z .* vortY * dA; % z flipped from paper, vortY also flipped
        term2 = -U * -z .* vortY; % z flipped from paper, vortY also flipped
        term3 = U * y .* vortZ;
        term4 = (u + U).^2;
        drag_mat = term2 + term3 + term4; % -term1
        % terms 2 and 3 end up being much smaller, perhaps the other terms
        % dropped in this analysis can't be dropped as before with lift

        drag_vec = trapz(y(:,1), drag_mat, 1);
        drag = 2 * density * trapz(z(1,:), drag_vec, 2);
        drag = squeeze(drag);
    else
        drag_mat_full = -u .* (u + U); % If w > U in magnitude, should be -
        
        drag_vec_full = trapz(y(:,1), drag_mat_full, 1);
        drag = 2 * density * trapz(z(1,:), drag_vec_full, 2);
        drag = squeeze(drag);
    end
    
end