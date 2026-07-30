clear
close all

ticksPerRev = 18432;
f_w = 8; % Hz, wingbeat frequency
N = 1:1:100; % number of phase points/bins
p = 1:1:50; % phase step size
[N_grid, p_grid] = meshgrid(N, p);

f_l = (f_w .* N_grid) ./ p_grid; % Hz, laser frequency
f_l_desired = 200;
f_l_unwrapped = f_l(:);
N_rep = N_grid(:);
p_rep = p_grid(:);
err = abs(f_l_unwrapped - f_l_desired);
% [M, I] = min(err);

% numMin = sum(err == M);
% 
% f_l_fin = f_l_unwrapped(I);
% N_fin = N_rep(I);
% p_fin = p_rep(I);

% Sort data according to error relative to 200 Hz laser frequency
[err_sorted, idx] = sort(err);

% remove all cases which exceed the max repitition rate of the laser
% and those which are too low
idx(f_l_unwrapped(idx) > 200) = [];
idx(f_l_unwrapped(idx) < 180) = [];

f_l_fin = f_l_unwrapped(idx);
N_fin = N_rep(idx);
p_fin = p_rep(idx);

% remove all redudant cases (different versions of same fraction)
step = p_fin ./ N_fin;
[~, ia] = unique(step, 'stable');  % 'stable' keeps first occurrence

f_l_fin = f_l_fin(ia);
N_fin = N_fin(ia);
p_fin = p_fin(ia);

% remove all cases where step size is not close to an integer in ticks
step = p_fin ./ N_fin;
step_in_ticks = ticksPerRev*step;
tol = 0.1;
ib = find(abs(step_in_ticks - round(step_in_ticks)) < tol);
f_l_fin = f_l_fin(ib);
N_fin = N_fin(ib);
p_fin = p_fin(ib);

% trimming to only show a few points
% num_pts = 10;
% f_l_fin = f_l_fin(1:num_pts);
% N_fin = N_fin(1:num_pts);
% p_fin = p_fin(1:num_pts);

step = p_fin ./ N_fin;
num_cycles = p_fin ./ gcd(N_fin, p_fin);

% number of PIV vector fields according to the camera datasheet
% numFrames = 21818 / 2;
numFrames = 5000; % number from experience on DaVis

disp("Wingbeat Frequency: " + f_w)
disp(N_fin + " datapoints, stepping " + step + " (" + ticksPerRev*step + " ticks) at a time, collected over " ...
    + num_cycles + " wingbeats, max of " + (numFrames ./ N_fin) ...
     + " cycles, laser frequency of " + f_l_fin)

% error over single cycle
err = (ticksPerRev*step - round(ticksPerRev*step)) .* N_fin;

% error over all cycles
% cycles = (numFrames ./ N_fin);
cycles = 60; % some limited number other than the max
err_total = err .* cycles;

err_total_deg = err_total .* (360 / ticksPerRev)

% disp(N_fin + " datapoints, stepping " + step + " (" + ticksPerRev*step + " ticks) at a time, collected over " ...
%     + num_cycles + " wingbeats before repeating and a maximum of " + (numFrames ./ N_fin) ...
%      + " cycles with a laser frequency of " + f_l_fin)
% p_fin + " wingbeats
% disp("i.e. " + p_fin ./ N_fin + ", " + 2 * (p_fin ./ N_fin))

% ascending = 1:1:200;
% wingbeat_phase = 17 + (1/2);
% res = test*(wingbeat_phase/20);
% tol = 1e-5;
% idx = find(abs(res - round(res)) < tol);
% wholeNumbers = idx;
% cyclesUntilLoop = wholeNumbers(1);
% 
% numFrames = 21818 / 2;
% numFullCycles = numFrames / (cyclesUntilLoop * wingbeat_phase);
% 
% wingbeat_freq = 10;
% disp(numFullCycles + " cycles collected with a resolution per cycle of " + cyclesUntilLoop*wingbeat_phase)
% disp("Recording data at a framerate of " + wingbeat_phase*wingbeat_freq)

% f_w = 10; % Hz
% N = (10:1:48)'; % number of phase points
% p = 1:1:10; % phase step size
% 
% [N_grid, p_grid] = meshgrid(N, p);
% 
% f_l = (f_w .* N_grid) ./ p_grid; % laser frequency
% f_l_desired = 200;
% 
% err = abs(f_l - f_l_desired);
% 
% % Mask out values above max repetition rate
% f_l(f_l > 200) = NaN;
% err(f_l > 200) = Inf;
% 
% % Flatten
% f_l_unwrapped = f_l(:);
% N_rep = N_grid(:);
% p_rep = p_grid(:);
% err_unwrapped = err(:);
% 
% [err_sorted, idx] = sort(err_unwrapped);
% num_pts = 20;
% 
% f_l_fin = f_l_unwrapped(idx(1:num_pts));
% N_fin = N_rep(idx(1:num_pts));
% p_fin = p_rep(idx(1:num_pts));
% 
% num_cycles = p_fin ./ gcd(N_fin, p_fin);
% 
% for i = 1:num_pts
%     fprintf('%d datapoints, stepping %.3f at a time, collected over %d wingbeats, to form %.1f cycles at %.1f Hz with laser frequency %.2f Hz\n', ...
%         N_fin(i), p_fin(i)/N_fin(i), p_fin(i), num_cycles(i), f_w, f_l_fin(i));
% end
