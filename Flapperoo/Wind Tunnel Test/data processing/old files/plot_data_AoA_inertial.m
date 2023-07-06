clear
close all

% Ronan Gissler April 2023

files = [["..\Experiment Data\inertial_mylar_0ms\AoA_0\0ms_2Hz_inertial_mylar_experiment_032323.csv",...
         "..\Experiment Data\inertial_mylar_0ms\AoA_10\10deg_0ms_2Hz_inertial_mylar_experiment_032323.csv"];...
         ["..\Experiment Data\inertial_mylar_0ms\AoA_0\0ms_3Hz_inertial_mylar_experiment_032323.csv",...
         "..\Experiment Data\inertial_mylar_0ms\AoA_10\10deg_0ms_3Hz_inertial_mylar_experiment_032323.csv"];...
         ["..\Experiment Data\inertial_mylar_0ms\AoA_0\0ms_4Hz_inertial_mylar_experiment_032323.csv",...
         "..\Experiment Data\inertial_mylar_0ms\AoA_10\10deg_0ms_4Hz_inertial_mylar_experiment_032323.csv"];...
         ["..\Experiment Data\inertial_mylar_0ms\AoA_0\0ms_5Hz_inertial_mylar_experiment_032323.csv",...
         "..\Experiment Data\inertial_mylar_0ms\AoA_10\10deg_0ms_5Hz_inertial_mylar_experiment_032323.csv"]];

frame_rate = 6000; % Hz
num_wingbeats = 180;

AoAs = [0, 10];

mean_lift = zeros(1, length(AoAs));
SD_lift = zeros(1, length(AoAs));
mean_norm_lift = zeros(1, length(AoAs));
SD_norm_lift = zeros(1, length(AoAs));

mean_pitch_mom = zeros(1, length(AoAs));
SD_pitch_mom = zeros(1, length(AoAs));
mean_norm_pitch_mom = zeros(1, length(AoAs));
SD_norm_pitch_mom = zeros(1, length(AoAs));

for k = 1:4
for i = 1:length(AoAs)
    % Get case name from file name
    case_name = erase(files(k, i), ["_inertial_mylar_experiment_032323.csv", "..\Experiment Data\inertial_mylar_0ms\AoA_"]);
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
save([char(case_parts(4)), '_inertial','.mat'], ...
     'mean_norm_lift','mean_norm_pitch_mom')
end

clearvars -except AoAs

AoAs = AoAs';

load 2Hz_inertial.mat
mean_norm_lift_2Hz = mean_norm_lift';
mean_norm_pitch_mom_2Hz = mean_norm_pitch_mom';

AoAs_model = [ones(length(AoAs),1) AoAs];
b_pitch_mom_2Hz = AoAs_model\mean_norm_pitch_mom_2Hz;
mean_norm_pitch_mom_2Hz_regression = AoAs_model*b_pitch_mom_2Hz;

load 3Hz_inertial.mat
mean_norm_lift_3Hz = mean_norm_lift';
mean_norm_pitch_mom_3Hz = mean_norm_pitch_mom';

b_pitch_mom_3Hz = AoAs_model\mean_norm_pitch_mom_3Hz;
mean_norm_pitch_mom_3Hz_regression = AoAs_model*b_pitch_mom_3Hz;

load 4Hz_inertial.mat
mean_norm_lift_4Hz = mean_norm_lift';
mean_norm_pitch_mom_4Hz = mean_norm_pitch_mom';

b_pitch_mom_4Hz = AoAs_model\mean_norm_pitch_mom_4Hz;
mean_norm_pitch_mom_4Hz_regression = AoAs_model*b_pitch_mom_4Hz;

load 5Hz_inertial.mat
mean_norm_lift_5Hz = mean_norm_lift';
mean_norm_pitch_mom_5Hz = mean_norm_pitch_mom';

b_pitch_mom_5Hz = AoAs_model\mean_norm_pitch_mom_5Hz;
mean_norm_pitch_mom_5Hz_regression = AoAs_model*b_pitch_mom_5Hz;

f = figure;
f.Position = [200 200 1000 660];
hold on
plot(AoAs, mean_norm_lift_2Hz, ".", MarkerSize=20,DisplayName="2Hz");
plot(AoAs, mean_norm_lift_3Hz, ".", MarkerSize=20,DisplayName="3Hz");
plot(AoAs, mean_norm_lift_4Hz, ".", MarkerSize=20,DisplayName="4Hz");
plot(AoAs, mean_norm_lift_5Hz, ".", MarkerSize=20,DisplayName="5Hz");
xlim([-5 15])
xlabel("Angle of Attack (deg)")
ylabel("Average Lift Coefficient")
title("Lift relationship with Angle of Attack")
legend(Location="northwest")

f = figure;
f.Position = [200 200 1000 660];
hold on
plot(AoAs, mean_norm_pitch_mom_2Hz, ".", MarkerSize=20,DisplayName="2Hz");
plot(AoAs, mean_norm_pitch_mom_2Hz_regression,"--","DisplayName","y = " + b_pitch_mom_2Hz(2) + "x + " + b_pitch_mom_2Hz(1));
plot(AoAs, mean_norm_pitch_mom_3Hz, ".", MarkerSize=20,DisplayName="3Hz");
plot(AoAs, mean_norm_pitch_mom_3Hz_regression,"--","DisplayName","y = " + b_pitch_mom_3Hz(2) + "x + " + b_pitch_mom_3Hz(1));
plot(AoAs, mean_norm_pitch_mom_4Hz, ".", MarkerSize=20,DisplayName="4Hz");
plot(AoAs, mean_norm_pitch_mom_4Hz_regression,"--","DisplayName","y = " + b_pitch_mom_4Hz(2) + "x + " + b_pitch_mom_4Hz(1));
plot(AoAs, mean_norm_pitch_mom_5Hz, ".", MarkerSize=20,DisplayName="5Hz");
plot(AoAs, mean_norm_pitch_mom_5Hz_regression,"--","DisplayName","y = " + b_pitch_mom_5Hz(2) + "x + " + b_pitch_mom_5Hz(1));
xlim([-5 15])
xlabel("Angle of Attack (deg)")
ylabel("Average Pitching Moment Coefficient")
title("Pitching Moment relationship with Angle of Attack")
legend(Location="southwest")