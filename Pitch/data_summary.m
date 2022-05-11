clear variables;
clc;
close all;

results_file_name = "longitudinal_stability_results_051122.mat";

load(results_file_name, 'max_alpha', 'min_alpha', 'offsets', 'results');
% disp(max_alpha);
% disp(min_alpha);

num_angles = max_alpha - min_alpha + 1;
angles = min_alpha:max_alpha;



mean_forces = zeros(num_angles, 6);
se_forces = zeros(num_angles, 6);

for angle_id = 1:num_angles
    angle = angles(angle_id);
    disp("Angle: " + angle);
    these_results = results{angle_id, 1};
    forces = these_results(:, 2:7);
    
    
    for force_id = 1:6
        force = forces(:, force_id);
        
        mean_force = mean(force);
        se_force = std(force) / sqrt(length(force));
        
        mean_forces(angle_id, force_id) = mean_force;
        se_forces(angle_id, force_id) = se_force;

        disp("Mean: " + mean_force);
%         disp(median_force);
%         disp(std_force);
        disp("Standard Error: " + se_force);
    end
end

hold on;
for force_id = 1:6
    mean_force = mean_forces(:, force_id);
    plot(angles, mean_force)
end