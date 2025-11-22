function make_movie_calc_circ(x, y, u, v, vort, Q, params)

    folder_name = params.PIV_case_name + "\" + params.folder + "\";

    if ~exist(params.save_filepath + folder_name, 'dir')
        mkdir(params.save_filepath + folder_name);
    end

    % ---------------------------------------
    % Calculating annular region where wingtip vortex might lie

    % xc = 0;   % center x
    % yc = 0;   % center y
    % R1 = 0.5;   % inner radius
    % R2 = 3;   % outer radius
    % 
    % dist = sqrt((x - xc).^2 + (y - yc).^2);
    % mask_r = (dist >= R1) & (dist <= R2);
    % 
    % % theta0 = pi; 
    % % theta = atan2(y - yc, x - xc);   % range: [-pi, pi]
    % % mask_theta = (theta >= theta0) & (theta <= theta0 + pi);
    % 
    % % mask = mask_r & mask_theta;
    % mask = mask_r;
    % 
    % x_tr = x;
    % y_tr = y;
    % u_tr = u;
    % v_tr = v;
    % vort_phase_avg_tr = vort;
    % Q_phase_avg_tr = Q;
    % x_tr(~mask) = NaN;
    % y_tr(~mask) = NaN;
    % u_tr(~mask) = NaN;
    % v_tr(~mask) = NaN;
    % vort_phase_avg_tr(~mask) = NaN;
    % Q_phase_avg_tr(~mask) = NaN;

    % ---------------------------------------

    figure('Units','normalized','OuterPosition',[0.6292 0.0454 0.3667 0.8759]);
    % h = contourf(x, y, val(:,:,1),71,'linestyle','none');   % first frame of your data
    % ax = gca;
    
    circ = zeros(1,params.num_bins);
    % --- Animation loop ---
    for k = 1:params.num_bins
        cur_frame_u = u(:,:,k);
        cur_frame_v = v(:,:,k);
        cur_frame_Q = Q(:,:,k);
        h = contourf(x, y, cur_frame_Q, 71,'linestyle','none');
        hold on

        % mask = Q(:,:,k) > params.cmin;           % logical mask
        % B = bwboundaries(mask);         % extract polygon(s)

        % Help identify tip vortex to start
        % if k == 1
            x_idx = find(x(1,:) > 0.5);  % columns
            
            x_tr = x(:, x_idx);
            y_tr = y(:, x_idx);
            Q_tr = cur_frame_Q(:, x_idx);

            [maxVal, linIdx] = max(Q_tr(:));       % get value and linear index
            [row, col] = ind2sub(size(Q), linIdx);
            xc = x_tr(row,col);
            yc = y_tr(row,col);
        % else
        %     [maxVal, linIdx] = max(cur_frame_Q(:));       % get value and linear index
        %     [row, col] = ind2sub(size(Q), linIdx);
        %     xc = x(row,col);
        %     yc = y(row,col);
        % end

        % Check that new peak center falls within radius of last search
        % circle
        if k~= 1 && ~inpolygon(xc, yc, x_pol, y_pol)
            disp("Peak outside old radius")
            % continue;
        end

        R  = 0.5; % meters, 0.025
        
        dist = sqrt((x - xc).^2 + (y - yc).^2);
        mask = dist <= R;
        
        ds = abs(x(1,1) - x(1,2));
        vort_tr = vort(mask);
        % circ(k) = sum(vort_tr*ds^2);

        x_circ = x;
        y_circ = y;
        x_circ(~mask) = NaN;
        y_circ(~mask) = NaN;

        h = pcolor(x_circ, y_circ, ones(size(x_circ)));

        shading flat                 % removes the grid lines between cells
        set(h, 'EdgeColor', 'none')  % removes borders
        
        % Make it a transparent blue overlay:
        set(h, 'FaceColor', 'blue', ...
               'FaceAlpha', 0.1);   % adjust transparency 0 (invisible) to 1 (opaque)

        % find boundary around the mask
        B = bwboundaries(mask);

        xb_all = [];
        yb_all = [];
        ub_all = [];
        vb_all = [];
        for j = 1:length(B)
            boundary = B{j};
            xb = x(sub2ind(size(x),boundary(:,1), boundary(:,2)));
            yb = y(sub2ind(size(y),boundary(:,1), boundary(:,2)));
            ub = cur_frame_u(sub2ind(size(y),boundary(:,1), boundary(:,2)));
            vb = cur_frame_v(sub2ind(size(y),boundary(:,1), boundary(:,2)));
            % plot(xb, yb, 'k-', 'LineWidth', 2);

            xb_all = [xb_all; xb];
            yb_all = [yb_all; yb];
            ub_all = [ub_all; ub];
            vb_all = [vb_all; vb];
        end
        pts = [xb_all, yb_all];
        try
        K = convhull(pts(:,1), pts(:,2));

        x_pol = pts(K,1);
        y_pol = pts(K,2);
        plot(x_pol, y_pol, 'k-', 'LineWidth', 2);

        ub_tr = zeros(size(x_pol));
        vb_tr = zeros(size(x_pol));

        for m = 1:length(x_pol)
            ub_tr(m) = u(x == x_pol(m) & y == y_pol(m));
            vb_tr(m) = v(x == x_pol(m) & y == y_pol(m));
        end

        % Calculate circulation along contour enclosing vortex
        for j = 1:length(x_pol)
            if j == length(x_pol)
                dx = x_pol(1) - x_pol(j);
                dy = y_pol(1) - y_pol(j);
                u_cur = (ub_tr(j) + ub_tr(1))/2;
                v_cur = (vb_tr(j) + vb_tr(1))/2;
            else
                dx = x_pol(j+1) - x_pol(j);
                dy = y_pol(j+1) - y_pol(j);
                u_cur = (ub_tr(j) + ub_tr(j+1))/2;
                v_cur = (vb_tr(j) + vb_tr(j+1))/2;
                if j == 1
                    % indicates direction of contour integration, should be
                    % CCW
                    quiver(x_pol(j), y_pol(j), dx, dy, 10,'Color', 'k','LineWidth', 2);
                end
            end
            % disp((u_cur*dx + v_cur*dy))
            circ(k) = circ(k) + (u_cur*dx + v_cur*dy);
            % u dx + v dy
        end
        end

        % Plot annular region where tip vortex may be
        % h = pcolor(x_tr, y_tr, ones(size(x_tr)));
        % 
        % shading flat                 % removes the grid lines between cells
        % set(h, 'EdgeColor', 'none')  % removes borders
        % 
        % % Make it a transparent blue overlay:
        % set(h, 'FaceColor', 'black', ...
        %        'FaceAlpha', 0.1);   % adjust transparency 0 (invisible) to 1 (opaque)

        axis equal
        % shading(ax, 'interp');
        xlim(params.xlims)
        ylim(params.ylims)
        xlabel("x/c", FontSize=16)
        ylabel("y/c", FontSize=16)
        % xlabel("x [m]", FontSize=16)
        % ylabel("y [m]", FontSize=16)
        % Xiaowei color map
        % min_vort = min(vort_phase_avg,[],'all');
        % max_vort = max(vort_phase_avg,[],'all');
        % vort_scale = max(abs([min_vort max_vort]));
        cb = colorbarpzn(params.clims(1), params.clims(2), 'dft','pwg'); % , 'level', 21
        % clim([-100 100]);
        % colormap(ax, jet);
        % colorbar;
        title(params.title + ", Circ = " + circ(k) + ", frame: " + k, Fontsize=18);

        drawnow;

        filename = sprintf('frame_%04d.png', k);  
        try
        exportgraphics(gcf, params.save_filepath + folder_name + filename, 'Resolution', 300);
        catch ME
            if k > 1
                disp("Oops, lost connection with LRS. Trying again...")
                pause(0.5)
                exportgraphics(gcf, params.save_filepath + folder_name + filename, 'Resolution', 300);
            else
                rethrow(ME);
            end
        end
    end
    
    fps = 5;
    gif_name = "animated";
    export_plot_gifs(params.save_filepath + params.PIV_case_name + "\" + params.folder + "\", gif_name, fps)

    figure
    plot(circ)
    ylabel("Circulation")

    folder = params.save_filepath + params.PIV_case_name;
    file_name = "circulation";
    saveas(gcf, folder + "\" + file_name + ".fig")
    exportgraphics(gcf, folder + "\" + file_name + ".png", 'Resolution', 300);

end