function W = add_wls_vorticity(file_path, opts)
% ADD_WLS_VORTICITY Recompute out-of-plane vorticity (omega_y, omega_z) for
% an existing *_phase_avg.mat file using all binned planes, weighted by the
% uncertainty of the phase-averaged velocity on each plane, and append the
% result to the file. No reprocessing of the raw DaVis data is needed.
%
%   W = add_wls_vorticity(file_path)
%   W = add_wls_vorticity(file_path, opts)
%
%   opts.sigmaMode  'plane' (default): one sigma per plane per phase bin,
%                   the median over that plane. Robust; captures "edge
%                   planes are noisier" without letting noisy pointwise
%                   sigma estimates steer the fit.
%                   'pointwise': sigma at every (plane, y, z).
%   opts.order      polynomial order across planes (default 2)
%   opts.transverseSmooth  see vorticity_slab_wls (default true)
%   opts.save       append results to file_path (default true)
%
%   Sigma of a phase-averaged velocity = (phase std) / sqrt(n), where n is
%   the number of valid vectors in that bin. If the file has n_valid_phase
%   (saved by phase_avg_STB after this change) that per-point count is
%   used; otherwise bin_count is used. bin_count overestimates n on
%   sparsely seeded edge planes, so their sigma comes out too small and
%   they get too much weight - rerun phase_avg_STB to save the per-point
%   counts if the edge planes have many holes.
%
%   Appended variables (nondimensional like vortY_phase_avg, same
%   [nx, ny, nz, num_bins] layout so trim_vel_field picks the centre plane;
%   only the centre plane is filled, other planes are NaN):
%     vortY_wls_phase_avg, vortZ_wls_phase_avg
%     vortY_wls_unc, vortZ_wls_unc          (1-sigma)
%     wls_vort_info                          (settings + plane sigmas)

if nargin < 2, opts = struct(); end
if ~isfield(opts, 'sigmaMode'), opts.sigmaMode = 'plane'; end
if ~isfield(opts, 'order'), opts.order = 2; end
if ~isfield(opts, 'transverseSmooth'), opts.transverseSmooth = true; end
if ~isfield(opts, 'save'), opts.save = true; end

vars_in_file = who('-file', file_path);
need = {'x','y','z','u_phase_avg','v_phase_avg','w_phase_avg', ...
        'u_phase_std','v_phase_std','w_phase_std','bin_count'};
missing = setdiff(need, vars_in_file);
if ~isempty(missing)
    error("add_wls_vorticity: %s is missing: %s", file_path, strjoin(missing, ", "));
end
load_list = need;
has_n = ismember('n_valid_phase', vars_in_file);
if has_n
    load_list{end+1} = 'n_valid_phase';
else
    warning("add_wls_vorticity:noCounts", ...
        "No n_valid_phase in %s; using bin_count for every point.", file_path);
end
D = load(file_path, load_list{:});

[nx, ny, nz, nb] = size(D.u_phase_avg);
i0 = (nx + 1) / 2;
vopts = struct('order', opts.order, 'i0', i0, 'transverseSmooth', opts.transverseSmooth);

vortY = nan(nx, ny, nz, nb);  vortZ = nan(nx, ny, nz, nb);
uncY  = nan(nx, ny, nz, nb);  uncZ  = nan(nx, ny, nz, nb);
plane_sigma = nan(nx, 3, nb);           % [plane, (u v w), bin]
chi2_w = nan(1, nb);

for k = 1:nb
    if has_n
        n = D.n_valid_phase(:,:,:,k);
    else
        n = D.bin_count(k) * ones(nx, ny, nz);
    end
    n(n < 2) = NaN;                     % no uncertainty estimate -> no weight

    su = make_sigma(D.u_phase_std(:,:,:,k) ./ sqrt(n), opts.sigmaMode);
    sv = make_sigma(D.v_phase_std(:,:,:,k) ./ sqrt(n), opts.sigmaMode);
    sw = make_sigma(D.w_phase_std(:,:,:,k) ./ sqrt(n), opts.sigmaMode);

    [wy, wz, sy, sz, info] = vorticity_slab_wls(D.x, D.y, D.z, ...
        D.u_phase_avg(:,:,:,k), D.v_phase_avg(:,:,:,k), D.w_phase_avg(:,:,:,k), ...
        su, sv, sw, vopts);

    % Fill the few columns without enough planes, as for the velocities
    vortY(i0,:,:,k) = reshape(fill3D(wy), 1, ny, nz);
    vortZ(i0,:,:,k) = reshape(fill3D(wz), 1, ny, nz);
    uncY(i0,:,:,k)  = reshape(sy, 1, ny, nz);
    uncZ(i0,:,:,k)  = reshape(sz, 1, ny, nz);

    plane_sigma(:,1,k) = median(reshape(su, nx, []), 2, "omitnan");
    plane_sigma(:,2,k) = median(reshape(sv, nx, []), 2, "omitnan");
    plane_sigma(:,3,k) = median(reshape(sw, nx, []), 2, "omitnan");
    chi2_w(k) = median(info.chi2red_w(:), "omitnan");
end

W.vortY_wls_phase_avg = vortY;
W.vortZ_wls_phase_avg = vortZ;
W.vortY_wls_unc = uncY;
W.vortZ_wls_unc = uncZ;
W.wls_vort_info = struct('sigmaMode', opts.sigmaMode, 'order', opts.order, ...
    'transverseSmooth', opts.transverseSmooth, 'used_point_counts', has_n, ...
    'plane_sigma', plane_sigma, 'plane_sigma_cols', {{'u','v','w'}}, ...
    'median_chi2red_w', chi2_w, 'created', string(datetime("now")));

% Relative weight each plane received (mean over bins), for a quick check
rel_w = squeeze(mean(1 ./ plane_sigma(:,3,:).^2, 3, "omitnan"));
fprintf("add_wls_vorticity: mean relative weight per plane (w): %s\n", ...
    mat2str(round(rel_w' / max(rel_w), 3)));

if opts.save
    save(file_path, '-struct', 'W', '-append');
    fprintf("add_wls_vorticity: appended WLS vorticity to %s\n", file_path);
end
end

% -------------------------------------------------------------------------
function s = make_sigma(s, mode)
% Clean up a sigma field and optionally collapse it to one value per plane.
nx = size(s, 1);
s(~isfinite(s) | s <= 0) = NaN;
plane_med = median(reshape(s, nx, []), 2, "omitnan");     % [nx, 1]
switch mode
    case 'plane'
        s = repmat(plane_med, [1, size(s, 2), size(s, 3)]);
    case 'pointwise'
        % Floor at 10% of the plane median so a few near-zero estimates
        % (e.g. hole-filled points) cannot dominate the fit.
        missing = isnan(s);
        s = max(s, 0.1 * plane_med);
        s(missing) = NaN;           % max() ignores NaN; keep them unweighted
    otherwise
        error("Unknown sigmaMode '%s'", mode);
end
end
