clear
close all

filepath = "R:\ENG_Breuer_Shared\rgissler\Calimero Flow Viz\Processed Results\processed data\";

filePattern = fullfile(filepath, '*.mat'); % Change to whatever pattern you need.
processed_files = dir(filePattern);

% colors = ["#fdbe85";"#fd8d3c";"#d94701"]; % reds
colors = [
    "#0072BD"
    "#D95319"
    "#EDB120"
    "#7E2F8E"
    "#77AC30"
    "#4DBEEE"
    "#A2142F"
];

amps = [10; 20; 30];

base_w = 0;

for i = 1:length(processed_files)
    name = processed_files(i).name;
    
    if contains(name, "body")
        fileToRemove = name;
        load(filepath + name, "net_w")
        avg_w = mean(net_w);

        base_w = avg_w;
        disp("Using " + name + " as base, avg_w = " + base_w)
    end

end

% remove this base case from the list of file names
processed_files(strcmp({processed_files.name}, fileToRemove)) = [];

figure
ax = gca;
xlabel("Wingbeat Frequency (Hz)")
% legend()
set(gca, FontSize=16)
hold on
% yyaxis left
ylabel("\boldmath$\frac{\bar{u}}{U_{\infty}}$",'Interpreter','Latex', FontSize=24)
ylabel("\boldmath$\big(\frac{\bar{u}}{U_{\infty}})_{robot} - \big(\frac{\bar{u}}{U_{\infty}})_{body}$",'Interpreter','Latex', FontSize=24)
% ylabel("Mean Freestream Velocity in Wake")
title(["Mean Freestream Velocity in Wake" ""])
% ax.YAxis(1).Color = colors(1);

for i = 1:length(processed_files)
    name = extractBefore(processed_files(i).name, ".");

    load(filepath + name, "net_w")
    avg_w = mean(net_w);
    
    name = string(strtrim(strrep(name,'_',' ')));
    
    % Parse relevant trial information from case name 
    parts = strtrim(split(name));

    for j = 1:length(parts)
        cur_str = parts(j);
        if contains(cur_str, "Hz")
            wing_freq = str2num(extractBefore(cur_str,"Hz"));     
        elseif startsWith(cur_str,"A")
            amp = str2num(extractAfter(cur_str, "A"));
        end
    end

    % c = colors(amps == amp);
    % if length(c) > 1
    %     error("c should have length 1")
    % end
    c = colors(1);

    % base case subtraction
    avg_w = avg_w - base_w;

    s = scatter(wing_freq, avg_w, 80, "filled", MarkerEdgeColor=c, MarkerFaceColor=c);
    % s = scatter(wing_freq, avg_w^2, 40, "filled", MarkerEdgeColor=c, MarkerFaceColor=c);
    
    if wing_freq == 2
        s.HandleVisibility="on";
        s.DisplayName = string(amp);
    else
        s.HandleVisibility="off";
    end
end

wing_freq_sel = [0, 2, 4, 6, 8];
AoA_sel = [-16:2:16];
AoA = 10;
wing_freq = [2,4,6,8];

% load("F:\Calimero Data\Calimero November 2025\plot data\Calimero\flexible_20_4m.s._saved_2025_12_27 17_28_26.mat",...
%     "avg_forces")
load("F:\Calimero Data\Calimero November 2025\plot data\Calimero\flexible_20_4m.s._norm_saved_2025_12_27 17_11_54",...
    "avg_forces")
% load("F:\Calimero Data\Calimero November 2025\plot data\Calimero\flexible_Sub_20_4m.s._saved_2026_01_01 20_46_41Sub_body",...
%     "avg_forces")
% load("F:\Calimero Data\Calimero November 2025\plot data\Calimero\flexible_Sub_20_4m.s._norm_saved_2026_01_01 20_17_54Sub_body",...
%     "avg_forces")

drag = squeeze(avg_forces(1, AoA_sel == AoA, ismember(wing_freq_sel, wing_freq)));

% yyaxis right
figure
hold on
xlabel("Wingbeat Frequency (Hz)")
ylabel("\boldmath$\overline{C}_D$",'Interpreter','Latex')
% ylabel("Mean Drag Coefficient")
ax = gca;
% ax.YDir = 'reverse';
% ax.YAxis(2).Color = colors(2);
title("Mean Drag Coefficient")
set(gca, FontSize=16)

c = colors(2);
scatter(wing_freq, drag, 80, "filled",MarkerEdgeColor=c, MarkerFaceColor=c)