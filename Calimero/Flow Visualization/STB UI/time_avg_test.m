clear
% close all

STB_path = "Y:\Processed Results\";

contents = dir(STB_path);
STB_files = contents(~[contents.isdir]);

selections = zeros(length(STB_files),3);

for i = 1:length(STB_files)
    name = STB_files(i).name;
    name = extractBefore(name, "_phase_avg");

    if ~contains(name, "Hz") % body or ring only case
        continue
    end
    name_parts = split(name,"_");

    for j = 1:length(name_parts)
        if contains(name_parts{j}, "deg")
            amp = str2double(extractBefore(name_parts{j}, "deg"));
            type = string(name_parts{j-1});
        elseif contains(name_parts{j}, "Hz")
            freq = str2double(extractBefore(name_parts{j}, "Hz"));
        end
    end

    % Add to list of amplitudes and frequencies
    selections(i,1) = 1;
    selections(i,2) = amp;
    selections(i,3) = freq;

    var_name = "drag_vel";
    % var_name = "drag";
    d = load(STB_path + name + "_phase_avg.mat", var_name);
    var = d.(var_name);

    selections(i,4) = mean(var);

    %% Get force data

    % 1. Define the parent directory
    parentDir = "Y:\Force Measurements\" + type + "_" + amp + "deg" + "\4 m.s\";
    
    % 2. Get a list of everything inside that folder
    % We filter for directories only ([parentDir, '\*']) to be safe
    contents = dir(parentDir);
    
    % 3. Remove the '.' and '..' (which are always present in file systems)
    % and filter for actual folders
    contents = contents([contents.isdir] & ~ismember({contents.name}, {'.', '..'}));
    
    % 4. Since there is only one folder, we grab the first (and only) name
    dynamicFolderName = contents(1).name;
    
    force_path = parentDir + dynamicFolderName + "\processed data\";
    
    contents = dir(force_path);
    force_files = contents(~[contents.isdir]);

    for j = 1:length(force_files)
        cur_name = force_files(j).name;
        if contains(cur_name, "10deg") && contains(cur_name, freq + "Hz")
            force_filename = cur_name;
        end
    end

    var_name_F = "wingbeat_avg_forces_raw";
    % var_name_F = "wingbeat_avg_forces";
    % var_name_F = "wingbeat_avg_forces_smoothest";
    % disp("Loading " + force_path + force_filename)
    c = load(force_path + force_filename, var_name_F);
    var_F = c.(var_name_F);

    if contains(var_name,"drag")
        idx = 1;
    elseif contains(var_name, "lift")
        idx = 3;
    end

    selections(i,5) = mean(var_F(idx,:));
end

% Deletes rows where all elements are 0 - body/ring case
selections(~any(selections, 2), :) = [];

amp_10 = selections(selections(:,2) == 10,:);
amp_20 = selections(selections(:,2) == 20,:);
amp_30 = selections(selections(:,2) == 30,:);

cmap = colororder();
sz = 40;
f = figure;
f.Position = [100 100 800 600];
hold on
scatter(amp_10(:,3), amp_10(:,4),sz,cmap(1,:),"filled", DisplayName="10 deg")
scatter(amp_20(:,3), amp_20(:,4),sz,cmap(2,:),"filled", DisplayName="20 deg")
scatter(amp_30(:,3), amp_30(:,4),sz,cmap(3,:),"filled", DisplayName="30 deg")

scatter(amp_10(:,3), amp_10(:,5),sz,cmap(1,:), DisplayName="10 deg F")
scatter(amp_20(:,3), amp_20(:,5),sz,cmap(2,:), DisplayName="20 deg F")
scatter(amp_30(:,3), amp_30(:,5),sz,cmap(3,:), DisplayName="30 deg F")
xlabel("Wingbeat Frequency")
ylabel("Force (N)")
legend()
