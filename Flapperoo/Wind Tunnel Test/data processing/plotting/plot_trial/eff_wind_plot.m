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

    wingbeats_animation = struct('cdata', cell(1,length(time)), 'colormap', cell(1,length(time)));
    for i = 1:length(time)
        % Open a new figure.
        fig = figure;
        fig.Visible = "off";
        hold on
        % yline(0, LineWidth=2, Color='black')
        quiver(p1(i, 1),p1(i, 2),dp(i, 1),dp(i, 2),0, LineWidth=2)
        quiver(p2(i, 1),p1(i, 2),p2(i, 1),dp(i, 2),0, LineWidth=2) % v_y
        quiver(p1(i, 1),p1(i, 2),dp(i, 1),p2(i, 2),0, LineWidth=2) % v_x
        text(p2(i, 1) + 0.2, p1(i, 2) + dp(i, 2)/2, "u_{wing}")
        if (p1(i, 2) > 0)
            text(p1(i, 1) + dp(i, 1)/2, p1(i, 2) + 0.5, "U_{\infty}")
            text(p1(i, 1) + dp(i, 1)/2 - 0.2, p1(i, 2) + dp(i, 2)/2 - 0.5, "u_{eff}")
        else
            text(p1(i, 1) + dp(i, 1)/2, p1(i, 2) - 0.5, "U_{\infty}")
            text(p1(i, 1) + dp(i, 1)/2 - 0.2, p1(i, 2) + dp(i, 2)/2 + 0.5, "u_{eff}")
        end
        
        xlim([-ceil(min(u_rel(:,251)) + 0.5) 1])
        ylim([-ceil(max(u_rel(:,251))) ceil(max(u_rel(:,251)))])
        set(gca,'XTick',[], 'YTick', [])
        % alpha(1)

        F = getframe(fig);
        
        % Add plot to array of plots to serve animation
        wingbeats_animation(i) = F;

        percent_complete = (i / length(time))*100;
        disp(round(percent_complete) + "% done with movie")
    end

    % Save movie
    video_name = 'eff_wind.mp4';
    v = VideoWriter(video_name, 'MPEG-4');
    v.FrameRate = 20; % fps
    v.Quality = 100; % [0 - 100]
    open(v);
    writeVideo(v,wingbeats_animation);
    close(v);
    end
end