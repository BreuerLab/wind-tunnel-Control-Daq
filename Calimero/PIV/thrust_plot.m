clear
close all

filepath = "R:\ENG_Breuer_Shared\rgissler\Calimero Flow Viz\Processed Results\processed data\";

filePattern = fullfile(filepath, '*.mat'); % Change to whatever pattern you need.
processed_files = dir(filePattern);

colors = ["#fdbe85";"#fd8d3c";"#d94701"];
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
xlabel("Wingbeat Frequency (Hz)")
% legend()
hold on
yyaxis left
ylabel("Mean w Velocity")

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

    c = colors(amps == amp);
    if length(c) > 1
        error("c should have length 1")
    end

    % base case subtraction
    avg_w = avg_w - base_w;

    s = scatter(wing_freq, avg_w, 40, "filled", MarkerEdgeColor=c, MarkerFaceColor=c);
    
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

load("F:\Calimero Data\Calimero November 2025\plot data\Calimero\flexible_20_4m.s._saved_2025_12_27 17_28_26.mat",...
    "avg_forces")

drag = squeeze(avg_forces(1, AoA_sel == AoA, ismember(wing_freq_sel, wing_freq)));

yyaxis right
ylabel("Mean Drag")
ax = gca;
ax.YDir = 'reverse';
scatter(wing_freq, drag, 40, "filled")