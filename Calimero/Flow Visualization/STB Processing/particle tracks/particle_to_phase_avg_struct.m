function S = particle_to_phase_avg_struct(R, binned_phase_file)
% PARTICLE_TO_PHASE_AVG_STRUCT  Repackage a particlePhaseAverage result R in
% the layout phase_avg_STB saves, so calc_secondary_vals_phase, flowField_UI
% and phaseAvg_UI can use it unchanged (saved under its own version name).
%
%   S = particle_to_phase_avg_struct(R, binned_phase_file)
%
% R must come from particlePhaseAverage with opts.saveGradients = true and
% all bins (R.bins = 1:num_bins).
%
% binned_phase_file : the binned-vector *_phase_avg.mat of the same case.
%   It supplies the case metadata (L, U, U_act, rho_act, binning, ...), the
%   target grid (the particle fit is resampled onto the binned y-z grid and
%   x-plane spacing, so the two compare node for node and the secondary
%   values cost the same), and the measurement uncertainty uncU/V/W. The particle fit has no per-point
%   uncertainty of its own, so the force integrals' uncertainty mask
%   (bounds.unc_mask) then removes the same regions as for the binned data,
%   which keeps the comparison like for like.
%
% LAYOUT (as import_STB_data / phase_avg_STB, nondimensional):
%   x, y, z            [3 ny nz]           positions / L
%   <field>_phase_avg  [3 ny nz num_bins]  velocities / U, vorticity and
%                                          gradients * L/U
% The particle fit gives one plane plus the full gradient tensor there.
% Three x-planes are built about it with a first-order Taylor expansion,
% u(x0 + dx) = u(x0) + dx * du/dx, so any central difference across them
% (trim_vel_field takes the middle plane; calQlate3D and the frozen-flow
% check difference across planes) returns exactly the fitted du/dx etc.
% Gradients and vorticity are the same on all three planes (linear field).
%
% Utot, Utot_diff, vortTot and hel are computed from the averaged fields,
% whereas the binned files average the per-frame values; the difference is
% second order for 2-3 pairs per bin.

    if ~isfield(R, 'G')
        error('particle_to_phase_avg_struct:G', ...
            'R has no gradients; run particlePhaseAverage with opts.saveGradients = true.');
    end

    % ---- metadata from the binned file ---------------------------------
    meta = {'L', 'U', 'rho', 'rho_act', 'U_act', 'Re', 'cycle_freq', 'num_bins', ...
            'tick_frame_pos', 'full_cycle', 'bin_ind_arr', 'bin_count', 'bin_std', ...
            'bin_phase_var', 'phase_res', 'bin_placement', 'num_clusters', ...
            'phase_spread_ratio', 'PIV_case_name'};
    vars = who('-file', char(binned_phase_file));
    need = {'L', 'U', 'U_act', 'rho_act', 'num_bins', 'PIV_case_name', 'x', 'y', 'z', ...
            'uncU_phase_avg', 'uncV_phase_avg', 'uncW_phase_avg'};
    miss = setdiff(need, vars);
    if ~isempty(miss)
        error('particle_to_phase_avg_struct:meta', '%s lacks: %s', binned_phase_file, strjoin(miss, ', '));
    end
    B = load(binned_phase_file, meta{ismember(meta, vars)}, 'x', 'y', 'z', ...
             'uncU_phase_avg', 'uncV_phase_avg', 'uncW_phase_avg');
    for k = 1:numel(meta)
        if isfield(B, meta{k}), S.(meta{k}) = B.(meta{k}); end
    end
    L = double(B.L);  U = double(B.U);
    nb = double(B.num_bins);
    if numel(R.bins) ~= nb || any(R.bins(:)' ~= 1:nb)
        error('particle_to_phase_avg_struct:bins', ...
            'R covers bins %s, but the case has %d bins; process all bins.', mat2str(R.bins([1 end])), nb);
    end
    if ~isequal(R.inPlaneAxes, [2 3])
        error('particle_to_phase_avg_struct:axes', 'Expected depth axis x (in-plane y, z).');
    end

    % ---- target grid: the binned file's own y-z grid (centre plane) --------
    % Resampling the fine particle grid onto it keeps memory and run time of
    % the secondary values like the binned case and compares node for node.
    ic = (size(B.y, 1) + 1) / 2;
    if ic ~= round(ic), error('particle_to_phase_avg_struct:planes', 'Binned file needs an odd number of planes.'); end
    yN = squeeze(B.y(ic, :, :));  zN = squeeze(B.z(ic, :, :));   % [ny nz], / L
    [ny, nz] = size(yN);
    yq = yN * L * 1000;  zq = zN * L * 1000;                     % mm, particle grid units

    % 3 x-planes about the fitted plane, same spacing and order as binned
    x0  = double(R.depthEval) / 1000 / L;
    dxk = [B.x(ic-1,1,1) - B.x(ic,1,1); 0; B.x(ic+1,1,1) - B.x(ic,1,1)];
    S.x = repmat(x0 + dxk, [1 ny nz]);
    S.y = repmat(reshape(yN, [1 ny nz]), [3 1 1]);
    S.z = repmat(reshape(zN, [1 ny nz]), [3 1 1]);

    g1 = double(R.A1(:, 1));  g2 = double(R.A2(1, :))';
    inside = yq >= g1(1) & yq <= g1(end) & zq >= g2(1) & zq <= g2(end);
    if mean(inside(:)) < 0.3
        warning('particle_to_phase_avg_struct:overlap', ...
            ['Only %.0f%% of the binned grid lies inside the particle grid. ' ...
             'Check that the binned file is nondimensional (y, z divided by L).'], 100 * mean(inside(:)));
    end
    rs = @(F3) resample3(F3, g1, g2, yq, zq, nb);                % [ny nz nb]

    % ---- nondimensional particle fields on the binned grid [ny nz nb] -------
    sc = L / U;                                   % for 1/s quantities
    u0 = rs(R.U) / U;  v0 = rs(R.V) / U;  w0 = rs(R.W) / U;
    names = {'dudx', 'dudy', 'dudz'; 'dvdx', 'dvdy', 'dvdz'; 'dwdx', 'dwdy', 'dwdz'};
    for i = 1:3
        for j = 1:3
            g.(names{i, j}) = rs(reshape(R.G(i, j, :, :, :), size(R.U))) * sc;
        end
    end
    vX = rs(R.omega_x) * sc;  vY = rs(R.omega_y) * sc;  vZ = rs(R.omega_z) * sc;

    % Holes (no valid particle fit). get_wake_lift requires NaN-free
    % vorticity and, like loadpiv, holes should be interpolated rather than
    % zeroed: zeroing removes circulation from poorly seeded vortex cores.
    % Holes enclosed by data (interior) are filled per bin by smooth
    % interpolation from their surroundings (regionfill); holes connected to
    % the border of the window (outside the lit region) are set to 0 there.
    % Velocities keep NaN and are filled by prepare_STB_wake_field.
    holes = isnan(vX) | isnan(vY) | isnan(vZ);
    g.vX = vX;  g.vY = vY;  g.vZ = vZ;           % fill vorticity and gradients alike
    fn = fieldnames(g);
    nInt = 0;
    for b = 1:nb
        hb = holes(:, :, b);
        if ~any(hb(:)), continue; end
        interior = imclearborder(hb);            % hole regions not touching the border
        nInt = nInt + nnz(interior);
        for f = 1:numel(fn)
            F2 = g.(fn{f})(:, :, b);
            F2(hb) = 0;
            if any(interior(:)), F2 = regionfill(F2, interior); end
            g.(fn{f})(:, :, b) = F2;
        end
    end
    for f = 1:numel(fn)                          % anything left (no fit at all)
        F = g.(fn{f});  F(isnan(F)) = 0;  g.(fn{f}) = F;
    end
    vX = g.vX;  vY = g.vY;  vZ = g.vZ;
    g = rmfield(g, {'vX', 'vY', 'vZ'});
    fprintf(['Particle fit missing at %.1f%% of binned-grid nodes x bins: %.1f%% interior ' ...
             '(interpolated), %.1f%% outside the lit region (vorticity 0)\n'], ...
            100 * mean(holes(:)), 100 * nInt / numel(holes), 100 * (nnz(holes) - nInt) / numel(holes));
    % ---- assemble [3 ny nz nb] fields ---------------------------------------
    plane = @(f0, dfdx) cat(1, reshape(f0 + dxk(1) * dfdx, [1 ny nz nb]), ...
                               reshape(f0,                 [1 ny nz nb]), ...
                               reshape(f0 + dxk(3) * dfdx, [1 ny nz nb]));
    same  = @(f) repmat(reshape(f, [1 ny nz nb]), [3 1 1 1]);

    u = plane(u0, g.dudx);  v = plane(v0, g.dvdx);  w = plane(w0, g.dwdx);
    S.u_phase_avg = u;  S.v_phase_avg = v;  S.w_phase_avg = w;
    S.vortX_phase_avg = same(vX);  S.vortY_phase_avg = same(vY);  S.vortZ_phase_avg = same(vZ);
    for i = 1:3
        for j = 1:3
            S.([names{i, j} '_phase_avg']) = same(g.(names{i, j}));
        end
    end

    % totals from NaN-free copies, like import_STB_data (nanToMedian)
    uf = fillNaNMedian(u);  vf = fillNaNMedian(v);  wf = fillNaNMedian(w);
    S.Utot_phase_avg      = sqrt(uf.^2 + vf.^2 + wf.^2);
    S.Utot_diff_phase_avg = sqrt((uf + 1).^2 + vf.^2 + wf.^2);
    S.vortTot_phase_avg   = sqrt(S.vortX_phase_avg.^2 + S.vortY_phase_avg.^2 + S.vortZ_phase_avg.^2);
    S.hel_phase_avg = (u .* S.vortX_phase_avg + v .* S.vortY_phase_avg + w .* S.vortZ_phase_avg) ...
                      ./ (S.vortTot_phase_avg .* S.Utot_phase_avg);
    nP = rs(R.N);  nP(isnan(nP)) = 0;
    S.numP_phase_avg = same(nP);

    % ---- measurement uncertainty: binned values on the same grid ------------
    % (centre plane on all three planes, NaN = no binned data = unreliable)
    for c = {'uncU', 'uncV', 'uncW'}
        src = squeeze(B.([c{1} '_phase_avg'])(ic, :, :, :));
        src(isnan(src)) = 1;
        S.([c{1} '_phase_avg']) = same(reshape(src, [ny nz nb]));
    end
    S.uncTot_phase_avg = sqrt(S.uncU_phase_avg.^2 + S.uncV_phase_avg.^2 + S.uncW_phase_avg.^2);

    % ---- provenance --------------------------------------------------------
    S.particle = struct('mode', R.mode, 'fitOpts', R.fitOpts, 'opts', R.opts, ...
                        'setPath', R.setPath, 'nPairs', R.nPairs, 'nValid', R.nValid, ...
                        'binned_phase_file', string(binned_phase_file));
end

% -------------------------------------------------------------------------
function out = resample3(F3, g1, g2, yq, zq, nb)
% linear interpolation of each bin's [n1 n2] particle field onto (yq, zq)
    out = nan([size(yq) nb]);
    for b = 1:nb
        Fi = griddedInterpolant({g1, g2}, double(F3(:, :, b)), 'linear', 'none');
        out(:, :, b) = Fi(yq, zq);
    end
end

function f = fillNaNMedian(f)
% replace NaNs with the median of each bin's volume (cf. nanToMedian)
    for b = 1:size(f, 4)
        fb = f(:, :, :, b);
        fb(isnan(fb)) = median(fb(:), 'omitnan');
        f(:, :, :, b) = fb;
    end
end
