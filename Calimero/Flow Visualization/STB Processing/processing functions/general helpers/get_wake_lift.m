function [lift, drag] = get_wake_lift(U, L, D, vort_bool, density)

    % ---------------------------------------------
    % --------- Make values dimensional -----------
    % ---------------------------------------------
    x = D.x;
    y = D.y*L;
    z = D.z*L;
    u = D.u*U;
    v = D.v*U;
    w = D.w*U;
    if vort_bool
    vortX = D.vortX / (L/U);
    vortY = D.vortY / (L/U);
    vortZ = D.vortZ / (L/U);
    end

    unc = D.unc;

    % mask regions where missing STB information
    % u(isnan(unc)) = NaN;
    % w(isnan(unc)) = NaN;
    if vort_bool
        default_value = 0;

    % if avg_type
    vortX(isnan(unc)) = default_value; %  & unc > 0.03
    vortY(isnan(unc)) = default_value;
    vortZ(isnan(unc)) = default_value;

    % dudy(isnan(unc)) = default_value;
    % dudz(isnan(unc)) = default_value;
    % end

    % vortX = medfilt3(vortX);
    % vortY = medfilt3(vortY);
    % vortZ = medfilt3(vortZ);

    % median filter for each image, rather than 3D wake
    filter_dim = [3 3];
    if ndims(vortX) == 3
        for k = 1:size(vortX,3)
        vortX(:,:,k) = medfilt2(vortX(:,:,k), filter_dim);
        vortY(:,:,k) = medfilt2(vortY(:,:,k), filter_dim);
        vortZ(:,:,k) = medfilt2(vortZ(:,:,k), filter_dim);
    
        % dudy(:,:,k) = medfilt2(dudy(:,:,k), filter_dim);
        % dudz(:,:,k) = medfilt2(dudz(:,:,k), filter_dim);
        end
    else
        vortX = medfilt2(vortX, filter_dim);
        vortY = medfilt2(vortY, filter_dim);
        vortZ = medfilt2(vortZ, filter_dim);
    end

    % Q_mask_bool = true;
    % if Q_mask_bool
    %     vortX(Q < 0) = 0;
    %     % disp("Q mask active")
    % end

    % Flooring the noise below some threshold makes the trends with
    % wingbeat frequency appear smoother, but appears to worsen agreement
    % for phase averaged data (b/w load cell and STB)
    if ndims(vortX) == 3
    % thresh = 0.1 * (U/L);
    % vortX(vortX < thresh & vortX > -thresh) = default_value;
    % vortY(vortY < thresh & vortY > -thresh) = default_value;
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

    % if vort_bool
    % Q_mask_bool = false;
    % if Q_mask_bool
    %     vortX(Q < 0) = 0;
    %     disp("Q mask active")
    % end
    % end

    % mean convection speed base on vortex centers
    % u_tmp = u;
    % u_tmp(Q <= 0.025) = NaN;
    % 
    % mean_u = squeeze(mean(u_tmp, "all", "omitnan"));

    %% Calculate lift
    if vort_bool
        lift = struct();

        % term1 = -U * dA * x .* -vortZ; 
        % term2 = (w + U) .* -v .* dA; % effectively zero
        % term1 = -U * y .* -vortX;
        % term1 = mean_u * y .* -vortX;
        term1 = -U .* y .* -vortX; % u or -U, doesn't seem to make a big diff
        term2 = -(u + U) .* -w; % effectively zero
        % term3 = y .* (w .* dudy - v .* dudz);
    
        lift_vec_wx = trapz(y(:,1), term1, 1);
        % lift_wx = 2 * density * trapz(z(1,:), lift_vec_wx, 2);
        lift_wx = 2 * density * trapz(z(1,:), lift_vec_wx, 2);
        lift_wx = squeeze(lift_wx);

        % Calculating lift using mean rather than trapz
        % L_y = abs(y(end,1) - y(1,1));
        % L_z = abs(z(1,end) - z(1,1));
        % lift_wx2 = 2 * density * squeeze(mean(term1, [1,2])) * (L_y*L_z);

        lift_vec_vel = trapz(y(:,1), term2, 1);
        lift_vel = 2 * density * trapz(z(1,:), lift_vec_vel, 2);
        lift_vel = squeeze(lift_vel);

        % lift_vec_du = trapz(y(:,1), term3, 1);
        % lift_du = 2 * density * trapz(z(1,:), lift_vec_du, 2);
        % lift_du = squeeze(lift_du);

        if ~(isscalar(x))
        x = flip(x);

        dx = abs(x(2) - x(1));
        dt = dx / U;

        x = x - (dx * length(x)) / 2;

        x_reshaped = reshape(x, 1, size(x,1), size(x,2));

        % x_reshaped = x_reshaped - (dx * length(x)) / 2;
        lift_wy_F = zeros(size(x));
        lift_wx_F_T = zeros(size(x));

        vortY_shifted = vortY;
        for i = 1:length(x_reshaped)
            % x_cur = x - x(i);
            % x_reshape_cur = reshape(x_cur, 1, size(x,1), size(x,2));

            term3 = vortY_shifted .* (-u);
            % term3 = vortY_shifted .* x_reshape_cur;

            % x_tr = x(x < 0.7);
            % term3 = term3(:,:,x_reshaped < 0.7);

            lift_mat_wy = trapz(y(:,1), term3, 1);
            lift_vec_wy = trapz(z(1,:), lift_mat_wy, 2);
            lift_vec_wy = lift_vec_wy .* x_reshaped;

            lift_wy = trapz(x, lift_vec_wy, 3);
            % lift_wy = trapz(x_cur, lift_vec_wy, 3);
            % lift_wy = trapz(x_tr, lift_vec_wy, 3);

            % lift_wy = lift_vec_wy(1) - lift_vec_wy(end);
            % lift_wy = -mean(lift_wy, 3);

            lift_wy_F(i) = squeeze(lift_wy);

            % vortY_shifted = circshift(vortY_shifted, 1, 3);

            % Testing same procedure for vortX term
            % lift_mat_wx_T = trapz(y(:,1), y .* -vortX, 1);
            % lift_vec_wx_T = trapz(z(1,:), lift_mat_wx_T, 2);
            % 
            % lift_wx_T = trapz(x, lift_vec_wx_T, 3);
            % lift_wx_F_T(i) = squeeze(lift_wx_T);

            x_reshaped = circshift(x_reshaped, 1, 3);
        end
        % lift_wy_F = 2 * density * lift_wy_F'; 

        % lift_wy_F = (circshift(lift_wy_F, -1) - circshift(lift_wy_F, 1)) / (2*dt);
        % lift_wy_F = density * lift_wy_F';
        % 
        % lift_wx = (circshift(lift_wx_F_T, -1) - circshift(lift_wx_F_T, 1)) / (2*dt);
        % lift_wx = density * lift_wx';

        % lift_wy_F = 2 * density * lift_wy_F' * (1 / (dt*length(x)));
        % lift_wx = 2 * density * lift_wx_F_T' * (1 / (dt*length(x)));

        % expression from June 10th 2026
        % lift_wy_F = 2 * density * lift_wy_F' * (1 / (dt*length(x)));

        % expression from June 19th 2026
        lift_wy_F = 2 * density * lift_wy_F' * (1 / (dt*length(x)));

        % lift_wx_F_T = 2 * density * lift_wx_F_T' * (1 / (dt*length(x)));

        % lift_wy_Fin = gradient(lift_wy_F, dt);

        % order = 3;
        % framelen = 11;
        % lift_wy_Fin = savitskyGolayDiff(lift_wy_F, order, framelen, dt);

        % lift_wy_F = lift_wy_F / (dt*length(x)*U);


        
        % term3 = U * vortY;
        % 
        % lift_vec_wy = trapz(y(:,1), term3, 1);
        % lift_wy = trapz(z(1,:), lift_vec_wy, 2);
        % 
        % lift_wy = squeeze(lift_wy);
        % lift_wy_F = 2 * density * lift_wy';

        total = lift_wx + lift_vel + lift_wy_F;
        lift.vortY = lift_wy_F;
        else
            total = lift_wx + lift_vel;
        end
        lift.vortX = lift_wx;
        lift.vel = lift_vel;
        lift.tot = total;
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
        drag_mat = term2 + term3; % -term1

        bernoulli_term = v.^2 + w.^2 + (u + U).^2;

        bernoulli_mat = trapz(y(:,1), bernoulli_term, 1);
        bernoulli_vec = trapz(z(1,:), bernoulli_mat, 2);
        bernoulli = density * squeeze(bernoulli_vec);

        drag_wy_mat = trapz(y(:,1), term2, 1);
        drag_wy_vec = trapz(z(1,:), drag_wy_mat, 2);
        drag_wy = 2 * density * squeeze(drag_wy_vec);

        % L_y = abs(y(end,1) - y(1,1));
        % L_z = abs(z(1,end) - z(1,1));
        % drag_wy = 2 * density * squeeze(mean(term2, [1,2])) * (L_y*L_z);

        drag_wz_mat = trapz(y(:,1), term3, 1);
        drag_wz_vec = trapz(z(1,:), drag_wz_mat, 2);
        drag_wz = 2 * density * squeeze(drag_wz_vec);
        % drag_mat = term2 + term3 + term4; % -term1
        % terms 2 and 3 end up being much smaller, perhaps the other terms
        % dropped in this analysis can't be dropped as before with lift

        % drag_vec = trapz(y(:,1), drag_mat, 1);
        % drag = 2 * density * trapz(z(1,:), drag_vec, 2);
        % drag = squeeze(drag);

        total = drag_wy + drag_wz;
        drag.vortY = drag_wy;
        drag.vortZ = drag_wz;
        drag.bernoulli = bernoulli;
        drag.tot = total;
    else
        drag_mat_full = -u .* (u + U); % If w > U in magnitude, should be -
        
        drag_vec_full = trapz(y(:,1), drag_mat_full, 1);
        drag = 2 * density * trapz(z(1,:), drag_vec_full, 2);
        drag = squeeze(drag);
    end
    
end