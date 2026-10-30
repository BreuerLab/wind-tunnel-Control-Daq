function T = mean_weighting_check(data_path, case_filter, force_var)
% MEAN_WEIGHTING_CHECK Compare the equal-weight mean of a phase-averaged
% wake force (what timeAvg_UI's "mean" uses) with the time-weighted mean
% that uses each bin's actual phase (bin_placement), for every case.
%
%   T = mean_weighting_check(data_path)
%   T = mean_weighting_check(data_path, case_filter)            % e.g. "x3_wings_20deg"
%   T = mean_weighting_check(data_path, case_filter, force_var) % default "lift.vortX"
%
%   data_path    the same root folder passed to phaseAvg_UI / timeAvg_UI
%   case_filter  optional text; only cases whose name contains it are used
%
%   Prints a table and plots both means against wingbeat frequency.

if nargin < 2, case_filter = ""; end
if nargin < 3, force_var = "lift.vortX"; end

folder = data_path + "Processed Results\phase_avg\";
files = dir(folder + "*_phase_avg.mat");
names = erase(string({files.name}), "_phase_avg.mat");
names = names(~contains(names, "turbine"));
if strlength(case_filter) > 0
    names = names(contains(names, case_filter));
end
if isempty(names)
    error("No *_phase_avg.mat cases found in %s matching '%s'", folder, case_filter);
end

n = numel(names);
freq = nan(n,1); m_equal = nan(n,1); m_time = nan(n,1); has_p = false(n,1);
for i = 1:n
    file = folder + names(i) + "_phase_avg.mat";
    [~, ~, freq(i)] = parse_name(names(i));

    F = get_PIV_force(file, names(i), force_var, 1, false, default_trim_bounds());
    F = F(:);
    m_equal(i) = mean(F, "omitnan");

    d = load(file, 'cycle_freq');
    period = 1 / d.cycle_freq;
    placement = [];
    if ismember('bin_placement', who('-file', file))
        p = load(file, 'bin_placement');
        placement = p.bin_placement;
        has_p(i) = true;
    end
    tb = bin_times(numel(F), period, placement);
    m_time(i) = periodic_mean(F, tb, period);
end

[freq, order] = sort(freq);
names = names(order); m_equal = m_equal(order); m_time = m_time(order); has_p = has_p(order);
T = table(names(:), freq, m_equal, m_time, m_time - m_equal, has_p, ...
    'VariableNames', {'case', 'freq_Hz', 'mean_equal_N', 'mean_time_weighted_N', 'difference_N', 'has_bin_placement'});
disp(T)

figure('Name', "Mean weighting check: " + force_var);
plot(freq, m_equal, 'o-', 'DisplayName', 'equal weight per bin'); hold on
plot(freq, m_time, 's--', 'DisplayName', 'time-weighted (actual bin phase)');
grid on; xlabel('Wingbeat frequency (Hz)'); ylabel(force_var + " mean (N)", 'Interpreter', 'none');
legend('Location', 'best');
end
