clear variables;
clc;
close all;

results_file_name = "longitudinal_stability_results_051122.mat";

load(results_file_name, 'max_alpha', 'min_alpha', 'offsets', 'results');
% disp(max_alpha);
% disp(min_alpha);

num_angles = max_alpha - min_alpha + 1;
angles = min_alpha:max_alpha;

for angle_id = 1:num_angles
    angle = angles(angle_id);
    disp(angle);
    forces = results{angle_id, 1};
    times = results{angle_id, 1};
    
    for force=forces
        mean_force = mean(force);
        median_force = median(force);
        std_force = std(force);
        se_force = std_force / sqrt(length(force));
        
        disp(mean_force);
        disp(median_force);
        disp(std_force);
        disp(se_force);
        disp("");
    end
end