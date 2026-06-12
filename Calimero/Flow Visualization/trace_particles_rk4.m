function [particle_path_x, particle_path_y, particle_path_z, ...
    particle_final_x, particle_final_y, particle_final_z] = trace_particles_rk4( ...
    particle_x0, particle_y0, particle_z0, num_particle_timesteps, particle_dt, ...
    is_inside_volume, wrap_x_periodic, x_axis, y_axis, z_axis, ...
    u_phase_avg, v_phase_avg, w_phase_avg)
%TRACE_PARTICLES_RK4 Integrate seeded particles through the velocity field.

grid_size = size(particle_x0);
num_particles = numel(particle_x0);
num_track_steps = num_particle_timesteps + 1;

particle_path_x = NaN(num_particles, num_track_steps);
particle_path_y = NaN(num_particles, num_track_steps);
particle_path_z = NaN(num_particles, num_track_steps);

particle_path_x(:,1) = particle_x0(:);
particle_path_y(:,1) = particle_y0(:);
particle_path_z(:,1) = particle_z0(:);

cur_x = particle_path_x(:,1);
cur_y = particle_path_y(:,1);
cur_z = particle_path_z(:,1);

for step_idx = 1:num_particle_timesteps
    valid_particles = is_inside_volume(cur_x, cur_y, cur_z);

    [k1_x, k1_y, k1_z] = sample_velocity_trilinear(wrap_x_periodic(cur_x), cur_y, cur_z, ...
        x_axis, y_axis, z_axis, u_phase_avg, v_phase_avg, w_phase_avg);

    k2_sample_x = wrap_x_periodic(cur_x + 0.5 * particle_dt * k1_x);
    [k2_x, k2_y, k2_z] = sample_velocity_trilinear(k2_sample_x, ...
        cur_y + 0.5 * particle_dt * k1_y, cur_z + 0.5 * particle_dt * k1_z, ...
        x_axis, y_axis, z_axis, u_phase_avg, v_phase_avg, w_phase_avg);

    k3_sample_x = wrap_x_periodic(cur_x + 0.5 * particle_dt * k2_x);
    [k3_x, k3_y, k3_z] = sample_velocity_trilinear(k3_sample_x, ...
        cur_y + 0.5 * particle_dt * k2_y, cur_z + 0.5 * particle_dt * k2_z, ...
        x_axis, y_axis, z_axis, u_phase_avg, v_phase_avg, w_phase_avg);

    k4_sample_x = wrap_x_periodic(cur_x + particle_dt * k3_x);
    [k4_x, k4_y, k4_z] = sample_velocity_trilinear(k4_sample_x, ...
        cur_y + particle_dt * k3_y, cur_z + particle_dt * k3_z, ...
        x_axis, y_axis, z_axis, u_phase_avg, v_phase_avg, w_phase_avg);

    % Keep x unwrapped to avoid discontinuities in the flow-map differences.
    next_x = cur_x + (particle_dt / 6) * (k1_x + 2 * k2_x + 2 * k3_x + k4_x);
    next_y = cur_y + (particle_dt / 6) * (k1_y + 2 * k2_y + 2 * k3_y + k4_y);
    next_z = cur_z + (particle_dt / 6) * (k1_z + 2 * k2_z + 2 * k3_z + k4_z);

    valid_particles = valid_particles & is_inside_volume(next_x, next_y, next_z);

    cur_x(:) = NaN;
    cur_y(:) = NaN;
    cur_z(:) = NaN;
    cur_x(valid_particles) = next_x(valid_particles);
    cur_y(valid_particles) = next_y(valid_particles);
    cur_z(valid_particles) = next_z(valid_particles);

    particle_path_x(:,step_idx + 1) = cur_x;
    particle_path_y(:,step_idx + 1) = cur_y;
    particle_path_z(:,step_idx + 1) = cur_z;

    if mod(step_idx, 5) == 0
        disp(step_idx)
    end
end

particle_final_x = reshape(particle_path_x(:,end), grid_size);
particle_final_y = reshape(particle_path_y(:,end), grid_size);
particle_final_z = reshape(particle_path_z(:,end), grid_size);
end
