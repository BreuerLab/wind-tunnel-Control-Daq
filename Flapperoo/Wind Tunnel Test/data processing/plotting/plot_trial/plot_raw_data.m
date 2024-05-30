function plot_raw_data(raw_time, raw_force, trimmed_time, trimmed_force, case_name, index)
    titles = ["F_{b,x}","F_{b,y}","F_{b,z}","M_{b,x}","M_{b,y}","M_{b,z}"];
    yLabs = ["Force (N)","Force (N)","Force (N)","Moment (N m)","Moment (N m)","Moment (N m)"];

    if (index == 0)
    % Open a new figure.
    f = figure;
    f.Position = [260, 160, 1250, 800];
    tcl = tiledlayout(2,3);
    
    % Create three subplots to show the force time histories. 
    nexttile(tcl)
    hold on
    raw_line = plot(raw_time, raw_force(1, :), 'DisplayName', 'Raw');
    trigger_line = plot(trimmed_time, trimmed_force(1, :), ...
        'DisplayName', 'Marked Motion');
    title(titles(1));
    xlabel("Time (s)");
    ylabel("Force (N)");
    
    nexttile(tcl)
    hold on
    plot(raw_time, raw_force(2, :));
    plot(trimmed_time, trimmed_force(2, :));
    title(titles(2));
    xlabel("Time (s)");
    ylabel("Force (N)");
    
    nexttile(tcl)
    hold on
    plot(raw_time, raw_force(3, :));
    plot(trimmed_time, trimmed_force(3, :));
    title(titles(3));
    xlabel("Time (s)");
    ylabel("Force (N)");

    % Create three subplots to show the moment time histories.
    nexttile(tcl)
    hold on
    plot(raw_time, raw_force(4, :));
    plot(trimmed_time, trimmed_force(4, :));
    title(titles(4));
    xlabel("Time (s)");
    ylabel("Moment (N m)");
    
    nexttile(tcl)
    hold on
    plot(raw_time, raw_force(5, :));
    plot(trimmed_time, trimmed_force(5, :));
    title(titles(5));
    xlabel("Time (s)");
    ylabel("Moment (N m)");
    
    nexttile(tcl)
    hold on
    plot(raw_time, raw_force(6, :));
    plot(trimmed_time, trimmed_force(6, :));
    title(titles(6));
    xlabel("Time (s)");
    ylabel("Moment (N m)");

    hL = legend([raw_line, trigger_line]);
    hL.Layout.Tile = 'East';
    sgtitle("Force Transducer Data for " + case_name)
    else
    figure;
    hold on
    plot(raw_time, raw_force(index, :),'DisplayName', 'Raw');
    plot(trimmed_time, trimmed_force(index, :),'DisplayName', 'Marked Motion');
    title(titles(index));
    xlabel("Time (s)");
    ylabel(yLabs(index));
    legend(Location="best")

    figure;
    hold on
    plot(trimmed_time - trimmed_time(1), trimmed_force(index, :),Color=[0.8500, 0.3250, 0.0980]);
    title(titles(index));
    xlabel("Time (s)");
    ylabel(yLabs(index));
    end
end