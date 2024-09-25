function plot_kinematics(time, ang_disp, ang_vel, lin_vel, lin_acc)

    % Just angular displacement
    fig = figure;
    fig.Position = [200 50 900 560];
    plot(time, ang_disp, DisplayName="Angular Displacement (deg)")
    xlim([0 max(time)])
    xlabel("Time (s)")
    ylabel("Angular Displacement (deg)")
    title("Angular Displacement of Wings Flapping at 1 Hz")

    % Just angular velocity
    fig = figure;
    fig.Position = [200 50 900 560];
    plot(time, ang_vel)
    xlim([0 max(time)])
    xlabel("Time (s)")
    ylabel("Angular Velocity (deg/s)")
    title("Angular Velocity of Wings Flapping at 1 Hz")

    % Both displacement and velocity
    fig = figure;
    fig.Position = [200 50 900 560];
    hold on
    yyaxis left
    plot(time, ang_disp, DisplayName="Angular Displacement (deg)")
    yyaxis right
    plot(time, ang_vel, DisplayName="Angular Velocity (deg/s)")
    hold off
    xlim([0 max(time)])
    xlabel("Time (s)")
    ylabel("Angular Displacement/Velocity")
    title("Angular Motion of Wings Flapping at 1 Hz")
    legend(Location="northeast")
    
    % Linear velocity
    fig = figure;
    fig.Position = [200 50 900 560];
    hold on
    plot(time, lin_vel(:,51), DisplayName="r = 0.05")
    plot(time, lin_vel(:,151), DisplayName="r = 0.15")
    plot(time, lin_vel(:,251), DisplayName="r = 0.25")
    xlim([0 max(time)])
    plot_wingbeat_patch();
    hold off
    xlabel("Time (s)")
    ylabel("Linear Velocity (m/s)")
    title("Linear Velocity of Wings Flapping at 1 Hz")
    legend(Location="northeast")
    
    % Linear acceleration
    fig = figure;
    fig.Position = [200 50 900 560];
    hold on
    plot(time, lin_acc(:,51), DisplayName="r = 0.05")
    plot(time, lin_acc(:,151), DisplayName="r = 0.15")
    plot(time, lin_acc(:,251), DisplayName="r = 0.25")
    xlim([0 max(time)])
    plot_wingbeat_patch();
    hold off
    xlabel("Time (s)")
    ylabel("Linear Acceleration (m/s^2)")
    title("Linear Acceleration of Wings Flapping at 1 Hz")
    legend(Location="northeast")

end