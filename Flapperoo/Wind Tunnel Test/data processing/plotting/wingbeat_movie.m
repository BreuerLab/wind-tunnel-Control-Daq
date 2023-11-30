function wingbeat_movie(frames, wingbeat_forces, case_name, subtitle, axes_labels)
    num_wingbeats = length(wingbeat_forces(1,:,1));
    wingbeats_animation = struct('cdata', cell(1,num_wingbeats), 'colormap', cell(1,num_wingbeats));

    for n = 1:num_wingbeats
        % Open a new figure.
        fig = figure;
        fig.Visible = "off";
        fig.Position = [200 50 1400 500];
        tcl = tiledlayout(1,3);
        sgtitle(["Force Transducer Measurement for " + case_name subtitle "wingbeat number: " + n]);
        
        nexttile(tcl)
        plot(frames, squeeze(wingbeat_forces(1, n, :)));
        grid
        title(["Drag"]);
        xlabel(axes_labels(1));
        ylabel(axes_labels(2));
        ylim([-3 3])
        
        nexttile(tcl)
        plot(frames, squeeze(wingbeat_forces(3, n, :)));
        grid
        title(["Lift"]);
        xlabel(axes_labels(1));
        ylabel(axes_labels(2));
        ylim([-6 12])
        
        nexttile(tcl)
        plot(frames, squeeze(wingbeat_forces(5, n, :)));
        grid
        title(["Pitch Moment"]);
        xlabel(axes_labels(1));
        ylabel(axes_labels(3));
        ylim([-5 4])
        
        % Save plot along with axes labels and titles
%         ax = gca;
%         ax.Units = 'pixels';
%         pos = ax.Position;
%         ti = ax.TightInset;
%         rect = [-ti(1), -ti(2), pos(3)+ti(1)+ti(3), pos(4)+ti(2)+ti(4)];
        F = getframe(fig);
        
        % Add plot to array of plots to serve animation
        wingbeats_animation(n) = F;
    end
    
    % Play movie
    % h = figure;
    % h.Position = [200 50 900 560];
    % movie(h,wingbeats_animation,5,5);
    
    % Save movie
    video_name = 'test.mp4';
    v = VideoWriter(video_name, 'MPEG-4');
    v.FrameRate = 5; % fps
    v.Quality = 100; % [0 - 100]
    open(v);
    writeVideo(v,wingbeats_animation);
    close(v);
    
    % From beginning to end, it looks like the data for each wingbeat is
    % slowly shifting right. This would indicate that the assumed wingbeat
    % period is a little shorter than the true wingbeat period or we are
    % not quite looking at a full 100 wingbeats
end