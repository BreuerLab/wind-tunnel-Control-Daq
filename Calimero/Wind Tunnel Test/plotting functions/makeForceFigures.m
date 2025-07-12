function [f1, f2, f3, f4, tiles_1, tiles_2, tiles_3, tiles_4] = makeForceFigures()
    % x_label = "Time (s)";
    % y_label_F = "Force (N)";
    % y_label_M = "Moment (N*m)";
    % axes_labels = [x_label, y_label_F, y_label_M];

    x_label = "Time (s)";
    y_label_F = "Force (N)";
    y_label_M = "Moment (N*m)";
    y_label_V = "Voltage (V)";
    y_label_C = "Current (mA)";
    y_label_P = "Angle (rad)";
    axes_labels = [x_label, y_label_F, y_label_M, y_label_V, y_label_C, y_label_P];

    f1 = figure;
    f1.Position = [0,323,1088,668];
    tcl = tiledlayout(2,3);
    tiles_1 = {nexttile, nexttile, nexttile, nexttile, nexttile, nexttile};
    for k = 1:6
        axes(tiles_1{k})
        xlabel(axes_labels(1));
        ylabel(axes_labels(1 + ceil(k/3)));
        title("Placeholder");
    end

    f2 = figure;
    f2.Position = [20,323,1088,668];
    tcl = tiledlayout(2,3);
    tiles_2 = {nexttile, nexttile, nexttile, nexttile, nexttile, nexttile};
    for k = 1:6
        axes(tiles_2{k})
        xlabel(axes_labels(1));
        ylabel(axes_labels(1 + ceil(k/3)));
        title("Placeholder");
    end

    f3 = figure;
    f3.Position = [1090 487 826 496];
    tcl = tiledlayout(1,3);
    tiles_3 = {nexttile, nexttile, nexttile};
    for j = 1:3
        axes(tiles_3{j})
        xlabel(axes_labels(1));
        ylabel(axes_labels(j+3));
        title("Placeholder");
    end

    f4 = figure;
    f4.Position = [1094 487 826 496];
    tcl = tiledlayout(1,3);
    tiles_4 = {nexttile, nexttile, nexttile};
    for j = 1:3
        axes(tiles_4{j})
        xlabel(axes_labels(1));
        ylabel(axes_labels(j+3));
        title("Placeholder");
    end
end

    % y_label = "Probability";
    % x_label_F = "Force (N)";
    % x_label_M = "Moment (N*m)";
    % axes_labels = [y_label, x_label_F, x_label_M];
    % 
    % f3 = figure;
    % f3.Position = [1940 600 1150 750];
    % tcl = tiledlayout(2,3);
    % tiles_3 = {nexttile, nexttile, nexttile, nexttile, nexttile, nexttile};
    % for k = 1:6
    %     axes(tiles_3{k})
    %     xlabel(axes_labels(1 + ceil(k/3)));
    %     ylabel(axes_labels(1));
    %     title("Placeholder");
    % end