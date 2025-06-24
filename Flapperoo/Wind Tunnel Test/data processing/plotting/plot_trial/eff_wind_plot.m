function eff_wind_plot(time, u_rel, eff_AoA, case_title)
    fig = figure;
    fig.Position = [200 50 900 560];
    hold on
    plot(time, u_rel(:,51), DisplayName="Near Wing Root") % "b = 0.05"
    % plot(time, u_rel(:,151), DisplayName="b = 0.15")
    plot(time, u_rel(:,251), DisplayName="Wing Tip") % "b = 0.25"
    set(gca,'DefaultLineLineWidth',2)
    xlim([0 max(time)])
    plot_wingbeat_patch();
    hold off
    xlabel("Time (s)")
    ylabel("Effective Wind Speed (m/s)")
    title(["Effective Wind Speed during Flapping" case_title...
           "Average Effective Wind Speed: " + mean(u_rel, "all")])
    legend(Location="northeast")

    fig = figure;
    fig.Position = [200 50 900 560];
    hold on
    plot(time, eff_AoA(:,51), DisplayName="Near Wing Root") 
    % plot(time, eff_AoA(:,151), DisplayName="b = 0.15")
    plot(time, eff_AoA(:,251), DisplayName="Wing Tip")
    set(gca,'DefaultLineLineWidth',2)
    xlim([0 max(time)])
    plot_wingbeat_patch();
    hold off
    xlabel("Time (s)")
    ylabel("Effective Angle of Attack (deg)")
    title(["Effective Angle of Attack during Flapping" case_title...
            "Average Effective AoA: " + mean(eff_AoA, "all")])
    legend(Location="northeast")

    movie_bool = true;
    if (movie_bool)
    % Animation showing effective wind vector moving relative to wing
    a_loc = 51;
    p1 = [-u_rel(:,a_loc).*cosd(eff_AoA(:,a_loc)) -u_rel(:,a_loc).*sind(eff_AoA(:,a_loc))];                         % First Point
    p2 = zeros(size(p1));                         % Second Point
    dp = p2 - p1;                         % Difference

    outputFolder = "temp_2";
    mkdir(outputFolder)

    % wingbeats_animation = struct('cdata', cell(1,length(time)), 'colormap', cell(1,length(time)));
    for i = 1:length(time)
        % Open a new figure.
        fig = figure;
        fig.Visible = "off";
        set(fig, 'Units','pixels','Position', [0, 0, 800, 800]);
        hold on
        % yline(0, LineWidth=2, Color='black')
        quiver(p1(i, 1), p1(i, 2), dp(i, 1), dp(i, 2), 0, LineWidth=4) % u_eff
        quiver(0, p1(i, 2), 0, dp(i, 2), 0, LineWidth=4) % v_y
        quiver(p1(i, 1), p1(i, 2), dp(i, 1), 0, 0, LineWidth=4) % v_x

        % Calculate angle between v_x and u_eff
        % Calculate the angle between the vectors
        A_vec = dp(i, :);
        B_vec = [dp(i, 1), 0];
        x_product = A_vec(1)*B_vec(2) - A_vec(2)*B_vec(1);
        magnitude_A = norm(A_vec);
        magnitude_B = norm(B_vec);
        scaled_product = x_product / (magnitude_A * magnitude_B);
        theta = asind(scaled_product); % Angle in degrees

        % disp(A_vec)
        % disp(B_vec)
        % disp("-------")
        % disp("-------")

        % XY location of points at middle of vectors to begin drawing arc
        u_eff_mid = p1(i, :) + dp(i, :) / 2;
        v_x_mid = [p1(i, 1) + dp(i, 1) / 2, p1(i, 2)];
        translated_vec = dp(i, :) / 2;
        translated_vec_s = dp(i, :) * (7 / 16);

        % arc_vector = [u_eff_mid; v_x_mid];
        % plot(arc_vector(:,1), arc_vector(:,2), Color="black")
        
        % Optionally, add a curved line or arc showing the angle
        t = linspace(0, theta, 100);
        arc = zeros(length(t),2);
        arc_text = zeros(length(t),2);
        for j = 1:length(t)
            rot = [cosd(t(j)), -sind(t(j));
                   sind(t(j)), cosd(t(j))];
            arc(j, :) = (rot * translated_vec') + p1(i, :)';
            arc_text(j,:) = (rot * translated_vec_s') + p1(i, :)';
        end
        % arc_x = norm(u_eff_mid)/2 * cosd(t);
        % arc_y = norm(u_eff_mid)/2 * sind(t);
        % plot(arc_x, arc_y, Color="black", LineWidth=3);
        plot(arc_text(:,1), arc_text(:,2), Color="black", LineWidth=3);

        % Labels for vectors
        f_s = 20;
        text(p2(i, 1) + 0.2, p1(i, 2) + dp(i, 2)/2, "u_{root}",FontSize=f_s)
        % text(arc(51,1), arc(51,2), "\alpha_{eff}",FontSize=f_s);
        if (p1(i, 2) > 0)
            text(p1(i, 1) + dp(i, 1)/2, p1(i, 2) + 0.5, "U_{\infty}",FontSize=f_s)
            text(p1(i, 1) + dp(i, 1)/2 - 0.2, p1(i, 2) + dp(i, 2)/2 - 0.5, "u_{eff}",FontSize=f_s)
        else
            text(p1(i, 1) + dp(i, 1)/2, p1(i, 2) - 0.5, "U_{\infty}",FontSize=f_s)
            text(p1(i, 1) + dp(i, 1)/2 - 0.2, p1(i, 2) + dp(i, 2)/2 + 0.5, "u_{eff}",FontSize=f_s)
        end
        
        xlim([-ceil(min(u_rel(:,251)) + 0.5) 1])
        ylim([-ceil(max(u_rel(:,251))) ceil(max(u_rel(:,251)))])
        set(gca,'XTick',[], 'YTick', [])
        % alpha(1)

        % F = getframe(fig);
        
        % Add plot to array of plots to serve animation
        % wingbeats_animation(i) = F;

        % set(fig, 'PaperPositionMode','auto');
        % set(fig, 'PaperSize',[800, 800]);
        % exportgraphics(fig,'testAnimated.gif','Append',true);
        exportgraphics(fig, fullfile(outputFolder, sprintf('frame%04d.png',i)), ...
            'Resolution',300)

        % saveas(fig, fullfile(outputFolder, sprintf('frame%04d.png',i)))
    
        % imwrite(getframe(fig).cdata, fullfile(outputFolder, sprintf('frame%04d.tif',i)), 'Resolution',[3200 3200])

        % dpi = 300;
        % print(fullfile(outputFolder, sprintf('frame%04d.png',i)), '-dpng', ['-r', num2str(dpi)]);

        percent_complete = (i / length(time))*100;
        disp(round(percent_complete) + "% done with movie")
    end

    % Save movie
    video_name = 'eff_wind.mp4';
    v = VideoWriter(video_name, 'MPEG-4');
    v.FrameRate = 20; % fps
    v.Quality = 100; % [0 - 100]

    open(v);

    % writeVideo(v,wingbeats_animation);

    frameFiles = dir(fullfile(outputFolder,'frame*.png'));
    for k = 1:length(frameFiles)
        % read each image
        img = imread(fullfile(outputFolder, frameFiles(k).name));
        writeVideo(v, img)
    end

    close(v);

    pause(1);
    % rmdir(outputFolder,'s')
    end
end