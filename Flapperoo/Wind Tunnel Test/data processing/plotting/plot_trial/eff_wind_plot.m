function eff_wind_plot(time, u_rel, eff_AoA, case_title)
    fig = figure;
    fig.Position = [200 50 900 560];
    hold on
    plot(time, u_rel(:,51), DisplayName="r = 0.05")
    plot(time, u_rel(:,151), DisplayName="r = 0.15")
    plot(time, u_rel(:,251), DisplayName="r = 0.25")
    xlim([0 max(time)])
    plot_wingbeat_patch();
    hold off
    xlabel("Time (s)")
    ylabel("Effective Wind Speed (m/s)")
    title(["Effective Wind Speed during Flapping" case_title])
    legend(Location="northeast")

    fig = figure;
    fig.Position = [200 50 900 560];
    hold on
    plot(time, eff_AoA(:,51), DisplayName="r = 0.05")
    plot(time, eff_AoA(:,151), DisplayName="r = 0.15")
    plot(time, eff_AoA(:,251), DisplayName="r = 0.25")
    xlim([0 max(time)])
    plot_wingbeat_patch();
    hold off
    xlabel("Time (s)")
    ylabel("Effective Angle of Attack (deg)")
    title(["Effective Angle of Attack during Flapping" case_title])
    legend(Location="northeast")
end