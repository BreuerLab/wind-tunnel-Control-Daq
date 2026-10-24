function HR = harmonic_regression_STB(accs, fields, phi_eval, frame_vals, frame_phi, opts)
% HARMONIC_REGRESSION_STB Phase-resolved STB fields by harmonic regression.
%
%   HR = harmonic_regression_STB(accs, fields, phi_eval, frame_vals, frame_phi, opts)
%
%   The alternative to bin-averaging in phase_avg_STB (bools.harmonic_reg).
%   Instead of averaging the frames in each phase bin, every point's time
%   series is fitted, over all frames at their actual phases, with a
%   Fourier series of opts.H wingbeat harmonics:
%       f(phi) = a0 + sum_h [ a_h cos(2 pi h phi) + b_h sin(2 pi h phi) ]
%   so there is no phase spread within a bin and no bin centroid offset,
%   noise above H times the wingbeat frequency is filtered out, and the fit
%   (and its exact time derivative) can be evaluated at any phase.
%
%   accs       - cell of accumulators from hr_accumulate (one per parallel
%                worker; frames are added as phase_avg_STB loads them)
%   fields     - field names, in the order of the accumulated data
%                (get_STB_processing_fields)
%   phi_eval   - phases (cycles) to evaluate the fits at. phase_avg_STB
%                uses the bin centres so the output is a drop-in
%                replacement for the bin averages.
%   frame_vals - (optional) struct of per-frame scalars to fit as well,
%                e.g. the lift computed on each frame. Fields may be
%                vectors or structs of vectors (one level).
%   frame_phi  - phase of each frame, matching frame_vals
%   opts.H         - number of harmonics (required)
%   opts.save_coef - also return the coefficients of every field
%                    (HR.coef.<field>, [nx ny nz K]); default false
%   opts.min_count, opts.rcond_tol - passed to hr_solve
%
%   HR.fields.<field> - fitted field at phi_eval, [nx ny nz numel(phi_eval)]
%   HR.coef.<field>   - coefficients (only with opts.save_coef)
%   HR.scalars        - per-frame scalars fitted at phi_eval (same nesting
%                       as frame_vals); HR.scalar_coef, HR.scalar_std hold
%                       their coefficients and the scatter about the fit
%   HR.info           - H, K, number of frames, conditioning, phases, and
%                       points left NaN (too few valid frames) per field

if nargin < 6 || ~isfield(opts, 'H')
    error("harmonic_regression_STB: opts.H (number of harmonics) is required")
end
if nargin < 4, frame_vals = struct(); end
save_coef = isfield(opts, 'save_coef') && opts.save_coef;
solve_opts = struct();
if isfield(opts, 'min_count'), solve_opts.min_count = opts.min_count; end
if isfield(opts, 'rcond_tol'), solve_opts.rcond_tol = opts.rcond_tol; end

% ----- fields -----
acc = hr_merge(accs);
clear accs
if isempty(acc)
    error("harmonic_regression_STB: no frames were accumulated")
end
if acc.H ~= opts.H
    error("harmonic_regression_STB: accumulated with %d harmonics, asked for %d", acc.H, opts.H)
end
if numel(fields) ~= acc.nf
    error("harmonic_regression_STB: %d field names for %d accumulated fields", numel(fields), acc.nf)
end

[coef, sinfo] = hr_solve(acc, solve_opts);
grid = acc.grid;
clear acc

E = harmonic_basis(phi_eval, opts.H);              % nphi x K
nphi = numel(phi_eval);
for f = 1:numel(fields)
    HR.fields.(fields{f}) = reshape(coef(:,:,f) * E.', [grid, nphi]);
    if save_coef
        HR.coef.(fields{f}) = reshape(coef(:,:,f), [grid, sinfo.K]);
    end
end
clear coef

HR.info = sinfo;
HR.info.phi_eval = phi_eval(:).';
HR.info.num_nan = cell2struct(num2cell(sinfo.num_nan(:)), fields(:), 1);
HR.info.num_corrected = cell2struct(num2cell(sinfo.num_corrected(:)), fields(:), 1);
HR.info.num_points = prod(grid);

% ----- per-frame scalars (e.g. lift on each frame) -----
HR.scalars = struct();
HR.scalar_coef = struct();
HR.scalar_std = struct();
names = fieldnames(frame_vals);
for k = 1:numel(names)
    val = frame_vals.(names{k});
    if isstruct(val)
        sub = fieldnames(val);
        for j = 1:numel(sub)
            [HR.scalars.(names{k}).(sub{j}), HR.scalar_coef.(names{k}).(sub{j}), ...
                HR.scalar_std.(names{k}).(sub{j})] = ...
                hr_fit_scalar(val.(sub{j}), frame_phi, opts.H, phi_eval);
        end
    else
        [HR.scalars.(names{k}), HR.scalar_coef.(names{k}), HR.scalar_std.(names{k})] = ...
            hr_fit_scalar(val, frame_phi, opts.H, phi_eval);
    end
end

fprintf("Harmonic regression: %d harmonics, %d frames, rcond %.2g\n", ...
    sinfo.H, sinfo.N, sinfo.rcond);
bad = find(sinfo.num_nan > 0);
for f = bad
    fprintf("  %s: %d of %d points left NaN (too few valid frames)\n", ...
        fields{f}, sinfo.num_nan(f), prod(grid));
end
end
