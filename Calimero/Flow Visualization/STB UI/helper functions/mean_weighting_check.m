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

folder = processed_results_dir(data_path) + "phase_avg\";
cases = stb_list_phase_avg(folder);
keep = ~contains(string({cases.label}), "turbine");
if strlength(case_filter) > 0
    keep = keep & contains(string({cases.label}), case_filter);
end
cases = cases(keep);
names = string({cases.label});
if isempty(names)
    error("No *_fields.mat cases found in %s matching '%s'", folder, case_filter);
end

n = numel(names);
freq = nan(n,1); m_equal = nan(n,1); m_time = nan(n,1); has_p = false(n,1);
for i = 1:n
    file = cases(i).files;   % case struct (stb_file_paths)
    [~, ~, freq(i)] = parse_name(names(i));

    F = get_PIV_force(file, names(i), force_var, 1, false, default_trim_bounds());
    F = F(:);
    m_equal(i) = mean(F, "omitnan");

    d = stb_load(file, 'cycle_freq');
    period = 1 / d.cycle_freq;
    placement = [];
    if ismember('bin_placement', stb_who(file))
        p = stb_load(file, 'bin_placement');
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
