clear
close all

% Ronan Gissler April 2023

files = [["..\Experiment Data\PDMS_heavy\3ms_AoA_0\0deg_3ms_0Hz_PDMS_heavy_experiment_032323.csv",...
         "..\Experiment Data\PDMS_heavy\3ms_AoA_2\0deg_3ms_0Hz_PDMS_heavy_experiment_032323.csv",...
         "..\Experiment Data\PDMS_heavy\3ms_AoA_4\4deg_3ms_0Hz_PDMS_heavy_experiment_032323.csv",...
         "..\Experiment Data\PDMS_heavy\3ms_AoA_6\6deg_3ms_0Hz_PDMS_heavy_experiment_032323.csv",...
         "..\Experiment Data\PDMS_heavy\3ms_AoA_8\8deg_3ms_0Hz_PDMS_heavy_experiment_032323.csv",...
         "..\Experiment Data\PDMS_heavy\3ms_AoA_10\10deg_3ms_0Hz_PDMS_heavy_experiment_032323.csv",...
         "..\Experiment Data\PDMS_heavy\3ms_AoA_12\12deg_3ms_0Hz_PDMS_heavy_experiment_032323.csv",...
         "..\Experiment Data\PDMS_heavy\3ms_AoA_14\14deg_3ms_0Hz_PDMS_heavy_experiment_032323.csv"];...
         ["..\Experiment Data\PDMS_heavy\3ms_AoA_0\0deg_3ms_2Hz_PDMS_heavy_experiment_032323.csv",...
         "..\Experiment Data\PDMS_heavy\3ms_AoA_2\0deg_3ms_2Hz_PDMS_heavy_experiment_032323.csv",...
         "..\Experiment Data\PDMS_heavy\3ms_AoA_4\4deg_3ms_2Hz_PDMS_heavy_experiment_032323.csv",...
         "..\Experiment Data\PDMS_heavy\3ms_AoA_6\6deg_3ms_2Hz_PDMS_heavy_experiment_032323.csv",...
         "..\Experiment Data\PDMS_heavy\3ms_AoA_8\8deg_3ms_2Hz_PDMS_heavy_experiment_032323.csv",...
         "..\Experiment Data\PDMS_heavy\3ms_AoA_10\10deg_3ms_2Hz_PDMS_heavy_experiment_032323.csv",...
         "..\Experiment Data\PDMS_heavy\3ms_AoA_12\12deg_3ms_2Hz_PDMS_heavy_experiment_032323.csv",...
         "..\Experiment Data\PDMS_heavy\3ms_AoA_14\14deg_3ms_2Hz_PDMS_heavy_experiment_032323.csv"];...
         ["..\Experiment Data\PDMS_heavy\3ms_AoA_0\0deg_3ms_3Hz_PDMS_heavy_experiment_032323.csv",...
         "..\Experiment Data\PDMS_heavy\3ms_AoA_2\0deg_3ms_3Hz_PDMS_heavy_experiment_032323.csv",...
         "..\Experiment Data\PDMS_heavy\3ms_AoA_4\4deg_3ms_3Hz_PDMS_heavy_experiment_032323.csv",...
         "..\Experiment Data\PDMS_heavy\3ms_AoA_6\6deg_3ms_3Hz_PDMS_heavy_experiment_032323.csv",...
         "..\Experiment Data\PDMS_heavy\3ms_AoA_8\8deg_3ms_3Hz_PDMS_heavy_experiment_032323.csv",...
         "..\Experiment Data\PDMS_heavy\3ms_AoA_10\10deg_3ms_3Hz_PDMS_heavy_experiment_032323.csv",...
         "..\Experiment Data\PDMS_heavy\3ms_AoA_12\12deg_3ms_3Hz_PDMS_heavy_experiment_032323.csv",...
         "..\Experiment Data\PDMS_heavy\3ms_AoA_14\14deg_3ms_3Hz_PDMS_heavy_experiment_032323.csv"];...
         ["..\Experiment Data\PDMS_heavy\3ms_AoA_0\0deg_3ms_3.5Hz_PDMS_heavy_experiment_032323.csv",...
         "..\Experiment Data\PDMS_heavy\3ms_AoA_2\0deg_3ms_3.5Hz_PDMS_heavy_experiment_032323.csv",...
         "..\Experiment Data\PDMS_heavy\3ms_AoA_4\4deg_3ms_3.5Hz_PDMS_heavy_experiment_032323.csv",...
         "..\Experiment Data\PDMS_heavy\3ms_AoA_6\6deg_3ms_3.5Hz_PDMS_heavy_experiment_032323.csv",...
         "..\Experiment Data\PDMS_heavy\3ms_AoA_8\8deg_3ms_3.5Hz_PDMS_heavy_experiment_032323.csv",...
         "..\Experiment Data\PDMS_heavy\3ms_AoA_10\10deg_3ms_3.5Hz_PDMS_heavy_experiment_032323.csv",...
         "..\Experiment Data\PDMS_heavy\3ms_AoA_12\12deg_3ms_3.5Hz_PDMS_heavy_experiment_032323.csv",...
         "..\Experiment Data\PDMS_heavy\3ms_AoA_14\14deg_3ms_3.5Hz_PDMS_heavy_experiment_032323.csv"];...
         ["..\Experiment Data\PDMS_heavy\3ms_AoA_0\0deg_3ms_4Hz_PDMS_heavy_experiment_032323.csv",...
         "..\Experiment Data\PDMS_heavy\3ms_AoA_2\0deg_3ms_4Hz_PDMS_heavy_experiment_032323.csv",...
         "..\Experiment Data\PDMS_heavy\3ms_AoA_4\4deg_3ms_4Hz_PDMS_heavy_experiment_032323.csv",...
         "..\Experiment Data\PDMS_heavy\3ms_AoA_6\6deg_3ms_4Hz_PDMS_heavy_experiment_032323.csv",...
         "..\Experiment Data\PDMS_heavy\3ms_AoA_8\8deg_3ms_4Hz_PDMS_heavy_experiment_032323.csv",...
         "..\Experiment Data\PDMS_heavy\3ms_AoA_10\10deg_3ms_4Hz_PDMS_heavy_experiment_032323.csv",...
         "..\Experiment Data\PDMS_heavy\3ms_AoA_12\12deg_3ms_4Hz_PDMS_heavy_experiment_032323.csv",...
         "..\Experiment Data\PDMS_heavy\3ms_AoA_14\14deg_3ms_4Hz_PDMS_heavy_experiment_032323.csv"];...
         ["..\Experiment Data\PDMS_heavy\3ms_AoA_0\0deg_3ms_4.5Hz_PDMS_heavy_experiment_032323.csv",...
         "..\Experiment Data\PDMS_heavy\3ms_AoA_2\0deg_3ms_4.5Hz_PDMS_heavy_experiment_032323.csv",...
         "..\Experiment Data\PDMS_heavy\3ms_AoA_4\4deg_3ms_4.5Hz_PDMS_heavy_experiment_032323.csv",...
         "..\Experiment Data\PDMS_heavy\3ms_AoA_6\6deg_3ms_4.5Hz_PDMS_heavy_experiment_032323.csv",...
         "..\Experiment Data\PDMS_heavy\3ms_AoA_8\8deg_3ms_4.5Hz_PDMS_heavy_experiment_032323.csv",...
         "..\Experiment Data\PDMS_heavy\3ms_AoA_10\10deg_3ms_4.5Hz_PDMS_heavy_experiment_032323.csv",...
         "..\Experiment Data\PDMS_heavy\3ms_AoA_12\12deg_3ms_4.5Hz_PDMS_heavy_experiment_032323.csv",...
         "..\Experiment Data\PDMS_heavy\3ms_AoA_14\14deg_3ms_4.5Hz_PDMS_heavy_experiment_032323.csv"];...
         ["..\Experiment Data\PDMS_heavy\3ms_AoA_0\0deg_3ms_5Hz_PDMS_heavy_experiment_032323.csv",...
         "..\Experiment Data\PDMS_heavy\3ms_AoA_2\0deg_3ms_5Hz_PDMS_heavy_experiment_032323.csv",...
         "..\Experiment Data\PDMS_heavy\3ms_AoA_4\4deg_3ms_5Hz_PDMS_heavy_experiment_032323.csv",...
         "..\Experiment Data\PDMS_heavy\3ms_AoA_6\6deg_3ms_5Hz_PDMS_heavy_experiment_032323.csv",...
         "..\Experiment Data\PDMS_heavy\3ms_AoA_8\8deg_3ms_5Hz_PDMS_heavy_experiment_032323.csv",...
         "..\Experiment Data\PDMS_heavy\3ms_AoA_10\10deg_3ms_5Hz_PDMS_heavy_experiment_032323.csv",...
         "..\Experiment Data\PDMS_heavy\3ms_AoA_12\12deg_3ms_5Hz_PDMS_heavy_experiment_032323.csv",...
         "..\Experiment Data\PDMS_heavy\3ms_AoA_14\14deg_3ms_5Hz_PDMS_heavy_experiment_032323.csv"]];

frame_rate = 6000; % Hz
num_wingbeats = 180;

AoAs = [0, 2, 4, 6, 8, 10, 12, 14];

mean_lift = zeros(1, length(files));
SD_lift = zeros(1, length(files));
mean_norm_lift = zeros(1, length(files));
SD_norm_lift = zeros(1, length(files));

mean_pitch_mom = zeros(1, length(files));
SD_pitch_mom = zeros(1, length(files));
mean_norm_pitch_mom = zeros(1, length(files));
SD_norm_pitch_mom = zeros(1, length(files));

for k = 1:7
for i = 1:length(files)
    % Get case name from file name
    case_name = erase(files(k, i), ["_experiment_032323.csv", "..\Experiment Data\PDMS_heavy\3ms_AoA_"]);
    case_name = strrep(case_name,'_',' ');
    case_name = strrep(case_name,'\',' ');
    case_parts = strtrim(split(case_name));
    speed = 0;
    for j=1:length(case_parts)
        if (contains(case_parts(j), "Hz"))
            speed = str2double(erase(case_parts(j), "Hz"));
        end
    end
    
    % Get data from file
    data = readmatrix(files(k, i));
    
    if (k==1)
    lift = data(:,4);
    
    mean_lift(i) = round(mean(lift), 3);
    SD_lift(i) = round(std(lift), 3);

    pitch_mom = data(:,6);
    mean_pitch_mom(i) = round(mean(pitch_mom), 3);
    SD_pitch_mom(i) = round(std(pitch_mom), 3);

    rho = 1.204; % kg/m^3 at 20 C 1 atm
    wing_area = 0.266 * 0.088 * 2; % m^2, roughly
    half_span = 0.266; % m, roughly
    wing_speed = 3;
    norm_factor = (0.5 * rho * wing_area * wing_speed^2);

    norm_lift = lift / norm_factor;
    mean_norm_lift(i) = round(mean(norm_lift), 3);
    SD_norm_lift(i) = round(std(norm_lift), 3);

    norm_pitch_mom = pitch_mom / (norm_factor * 0.088);

    mean_norm_pitch_mom(i) = round(mean(norm_pitch_mom), 3);
    SD_norm_pitch_mom(i) = round(std(norm_pitch_mom), 3);
    else
    % Trim all data based on trigger data
    these_trigs = data(:, 8);
    these_low_trigs_indices = find(these_trigs < 3);
    trigger_start_frame = these_low_trigs_indices(1);
    trigger_end_frame = these_low_trigs_indices(end);

    trimmed_data = data(trigger_start_frame:trigger_end_frame, :);

    trimmed_time = trimmed_data(:,1) - trimmed_data(1,1);

    trimmed_lift = trimmed_data(:,4);
    
    mean_lift(i) = round(mean(trimmed_lift), 3);
    SD_lift(i) = round(std(trimmed_lift), 3);

    trimmed_pitch_mom = trimmed_data(:,6);
    mean_pitch_mom(i) = round(mean(trimmed_pitch_mom), 3);
    SD_pitch_mom(i) = round(std(trimmed_pitch_mom), 3);

    rho = 1.204; % kg/m^3 at 20 C 1 atm
    wing_area = 0.266 * 0.088 * 2; % m^2, roughly
    half_span = 0.266; % m, roughly
    wing_speed = 3 + (0.5*pi*speed * half_span);
    norm_factor = (0.5 * rho * wing_area * wing_speed^2);

    norm_lift = trimmed_lift / norm_factor;
    mean_norm_lift(i) = round(mean(norm_lift), 3);
    SD_norm_lift(i) = round(std(norm_lift), 3);

    norm_pitch_mom = trimmed_pitch_mom / (norm_factor * 0.088);

    mean_norm_pitch_mom(i) = round(mean(norm_pitch_mom), 3);
    SD_norm_pitch_mom(i) = round(std(norm_pitch_mom), 3);
    end
end
save([char(case_parts(4)),'.mat'], ...
     'mean_norm_lift','mean_norm_pitch_mom')
end

clearvars -except AoAs

AoAs = AoAs';

load 0Hz.mat
mean_norm_lift_0Hz = mean_norm_lift';
mean_norm_pitch_mom_0Hz = mean_norm_pitch_mom';

AoAs_model = [ones(length(AoAs),1) AoAs];
b_pitch_mom_0Hz = AoAs_model\mean_norm_pitch_mom_0Hz;
mean_norm_pitch_mom_0Hz_regression = AoAs_model*b_pitch_mom_0Hz;

% mean_norm_lift_0Hz = [-0.39091, -0.40816, -0.43125, -0.44994, 0, 0, 0, 0];
% mean_norm_pitch_mom_0Hz = [0.035792, 0.121936, 0.21366, 0.30006, 0, 0, 0, 0];

load 2Hz.mat
mean_norm_lift_2Hz = mean_norm_lift';
mean_norm_pitch_mom_2Hz = mean_norm_pitch_mom';

AoAs_model = [ones(length(AoAs),1) AoAs];
b_pitch_mom_2Hz = AoAs_model\mean_norm_pitch_mom_2Hz;
mean_norm_pitch_mom_2Hz_regression = AoAs_model*b_pitch_mom_2Hz;

load 3Hz.mat
mean_norm_lift_3Hz = mean_norm_lift';
mean_norm_pitch_mom_3Hz = mean_norm_pitch_mom';

b_pitch_mom_3Hz = AoAs_model\mean_norm_pitch_mom_3Hz;
mean_norm_pitch_mom_3Hz_regression = AoAs_model*b_pitch_mom_3Hz;

load 3.5Hz.mat
mean_norm_lift_3_5Hz = mean_norm_lift';
mean_norm_pitch_mom_3_5Hz = mean_norm_pitch_mom';

b_pitch_mom_3_5Hz = AoAs_model\mean_norm_pitch_mom_3_5Hz;
mean_norm_pitch_mom_3_5Hz_regression = AoAs_model*b_pitch_mom_3_5Hz;

load 4Hz.mat
mean_norm_lift_4Hz = mean_norm_lift';
mean_norm_pitch_mom_4Hz = mean_norm_pitch_mom';

b_pitch_mom_4Hz = AoAs_model\mean_norm_pitch_mom_4Hz;
mean_norm_pitch_mom_4Hz_regression = AoAs_model*b_pitch_mom_4Hz;

load 4.5Hz.mat
mean_norm_lift_4_5Hz = mean_norm_lift';
mean_norm_pitch_mom_4_5Hz = mean_norm_pitch_mom';

b_pitch_mom_4_5Hz = AoAs_model\mean_norm_pitch_mom_4_5Hz;
mean_norm_pitch_mom_4_5Hz_regression = AoAs_model*b_pitch_mom_4_5Hz;

load 5Hz.mat
mean_norm_lift_5Hz = mean_norm_lift';
mean_norm_pitch_mom_5Hz = mean_norm_pitch_mom';

b_pitch_mom_5Hz = AoAs_model\mean_norm_pitch_mom_5Hz;
mean_norm_pitch_mom_5Hz_regression = AoAs_model*b_pitch_mom_5Hz;

f = figure;
f.Position = [200 200 1000 660];
hold on
% plot(AoAs, mean_norm_lift_0Hz, ".", MarkerSize=20);
plot(AoAs, mean_norm_lift_2Hz, ".", MarkerSize=20,DisplayName="2Hz");
plot(AoAs, mean_norm_lift_3Hz, ".", MarkerSize=20,DisplayName="3Hz");
plot(AoAs, mean_norm_lift_3_5Hz, ".", MarkerSize=20,DisplayName="3.5Hz");
plot(AoAs, mean_norm_lift_4Hz, ".", MarkerSize=20,DisplayName="4Hz");
plot(AoAs, mean_norm_lift_4_5Hz, ".", MarkerSize=20,DisplayName="4.5Hz");
plot(AoAs, mean_norm_lift_5Hz, ".", MarkerSize=20,DisplayName="5Hz");
xlabel("Angle of Attack (deg)")
ylabel("Average Lift Coefficient")
title("Lift relationship with Angle of Attack")
legend(Location="northwest")

f = figure;
f.Position = [200 200 1000 660];
hold on
% plot(AoAs, mean_norm_pitch_mom_0Hz, ".", MarkerSize=20,DisplayName="0Hz");
plot(AoAs, mean_norm_pitch_mom_2Hz, ".", MarkerSize=20,DisplayName="2Hz");
plot(AoAs, mean_norm_pitch_mom_2Hz_regression,"--","DisplayName","y = " + b_pitch_mom_2Hz(2) + "x + " + b_pitch_mom_2Hz(1));
plot(AoAs, mean_norm_pitch_mom_3Hz, ".", MarkerSize=20,DisplayName="3Hz");
plot(AoAs, mean_norm_pitch_mom_3Hz_regression,"--","DisplayName","y = " + b_pitch_mom_3Hz(2) + "x + " + b_pitch_mom_3Hz(1));
plot(AoAs, mean_norm_pitch_mom_3_5Hz, ".", MarkerSize=20,DisplayName="3.5Hz");
plot(AoAs, mean_norm_pitch_mom_3_5Hz_regression,"--","DisplayName","y = " + b_pitch_mom_3_5Hz(2) + "x + " + b_pitch_mom_3_5Hz(1));
plot(AoAs, mean_norm_pitch_mom_4Hz, ".", MarkerSize=20,DisplayName="4Hz");
plot(AoAs, mean_norm_pitch_mom_4Hz_regression,"--","DisplayName","y = " + b_pitch_mom_4Hz(2) + "x + " + b_pitch_mom_4Hz(1));
plot(AoAs, mean_norm_pitch_mom_4_5Hz, ".", MarkerSize=20,DisplayName="4.5Hz");
plot(AoAs, mean_norm_pitch_mom_4_5Hz_regression,"--","DisplayName","y = " + b_pitch_mom_4_5Hz(2) + "x + " + b_pitch_mom_4_5Hz(1));
plot(AoAs, mean_norm_pitch_mom_5Hz, ".", MarkerSize=20,DisplayName="5Hz");
plot(AoAs, mean_norm_pitch_mom_5Hz_regression,"--","DisplayName","y = " + b_pitch_mom_5Hz(2) + "x + " + b_pitch_mom_5Hz(1));
xlabel("Angle of Attack (deg)")
ylabel("Average Pitching Moment Coefficient")
title("Pitching Moment relationship with Angle of Attack")
legend(Location="southwest")