function out_file = make_wake_topology_movie(data_root, case_label, varargin)
% MAKE_WAKE_TOPOLOGY_MOVIE  Explainer movie of how flowField_UI's
% "phase avg: 3D plot" is built, for one case.
%
%   make_wake_topology_movie(data_root, case_label)
%   make_wake_topology_movie(data_root, case_label, 'Name', value, ...)
%   out_file = make_wake_topology_movie(...)
%
%   data_root   data root as given to flowField_UI (e.g.
%               "C:\Users\rgissler\Documents\STB Processed Results\")
%   case_label  the case as flowField_UI's case list names it, with the
%               method suffix of the HR / RPCA / HRPP buttons, e.g.
%               "x3_wings_20deg_8Hz_particle_pool_hr20" (HRPP) or
%               "x3_wings_20deg_8Hz" (binned)
%
% Storyboard (segment names in brackets, durations in opts.seg):
%   1 [w]        head-on view: the robot flaps, the plane behind it shows
%                the phase-averaged downwash w of the measured (one wing)
%                half, placed with the mirror's offset (centreline at y = 0)
%   1b [mirror]  the half is reflected about the centreline (flowField_UI
%                Mirror): the copy swings out to -y, giving both wings'
%                wake ('mirror', false leaves this out and stays one-sided)
%   2 [w_to_wx]  crossfade to the streamwise vorticity omega_x
%   3 [wx]       omega_x
%   4 [wx_to_Q]  crossfade to Q
%   5 [Q]        Q
%   6 [rotate]   camera moves from head-on to an isometric view
%   7 [build]    the Q isosurfaces are built behind the plane by frozen
%                flow: each phase the plane sees is laid out at
%                x = U (t_now - t_shed), so the wake grows downstream
%   8 [reveal]   the plane fades to its green outline, the isosurfaces
%                take on omega_x colours and lose their lighting (unlit,
%                as the GUI's 3D plot)
%   9 [hold]     the finished picture (optional slow orbit)
%
% Conventions follow "phase avg: 3D plot" with the x/c axis and Robot on:
% the plane at x/c = 0, the wake downstream to +x, x/c = U t / c (U the
% freestream speed, as in stack_vortices_3D), the robot drawn with its
% tail ROBOT_GAP_C upstream of the plane and its wings at the phase the
% fluid at the plane was shed at (bin phase minus dist * f / CONV_SPEED,
% as update_robot_3D). The plane fields and Q get the GUI's default
% processing (trim, mirror, median filter; for the isosurface also the 3%
% uncertainty mask and Remove Small 1%). The phase bins are upsampled by
% Fourier interpolation (interpft) so the flapping and the convecting
% wake are smooth; 'upsample', 1 gives the GUI's own bins.
%
% The wake's isosurface is computed once over every phase the movie
% shows and then only slid downstream and trimmed per frame (as the GUI's
% Play / convection shift, ensure_3D_ext / place_3D_ext).
%
% Every graphics object is created once and only updated per frame. All
% colours are truecolor, so the plane, the grey / omega_x isosurfaces and
% the robot can use different colormaps in the same axes; the axes
% colormap only drives the colorbar.
%
% Tuning: 'preview', true renders a small, low frame rate version quickly;
% 'segments', ["build" "reveal"] renders only those segments (the clock,
% camera and wake still follow the full storyboard, so they splice back).
%
% Needs on the path (main_analysis: addpath(genpath('../../'))): STB
% processing helpers (stb_list_phase_avg, stb_load), Robot Rendering
% (load_robot_model, robot_posed_mesh), Calimero Properties
% (calimero_mechanism, get_calimero_dims), Plotting (colorbarpzn) and
% STB UI\helper functions (processed_results_dir, plane_downstream_dists).
%
% Example:
%   make_wake_topology_movie("C:\Users\rgissler\Documents\STB Processed Results\", ...
%       "x3_wings_20deg_8Hz_particle_pool_hr20", 'preview', true)

%% ------------------------------------------------------------ options
o = default_options();
o = parse_options(o, varargin{:});
if o.preview
    o.fps = o.preview_fps;
    o.resolution = o.preview_resolution;
    o.upsample = min(o.upsample, 2);
end
case_label = string(case_label);

%% ------------------------------------------------------------ the case
phase_dir = processed_results_dir(data_root) + "phase_avg\";
cases = stb_list_phase_avg(phase_dir);
k = find(string({cases.label}) == case_label, 1);
if isempty(k)
    error("make_wake_topology_movie:case", "No case '%s' in %s. Available: %s", ...
        case_label, phase_dir, strjoin(string({cases.label}), ", "));
end
case_files = cases(k).files;
stem = string(cases(k).stem);

% imaging plane, its distance from the robot and the trim box
[plane_type, dist, trim_y, trim_z, mirror_c] = plane_info(stem, o);
amp = regexp(stem, "(\d+)deg", "tokens", "once");
if isempty(amp)
    error("make_wake_topology_movie:amp", "No wingbeat amplitude (..._20deg_...) in '%s'", stem);
end
amp = str2double(amp(1));

%% ------------------------------------------------------------ load
vars = ["L", "U", "num_bins", "cycle_freq", "y", "z", ...
        o.var_w, o.var_wx, o.var_Q];
if o.unc_mask_pct > 0
    vars(end+1) = "uncTot_phase_avg";
end
d = stb_load(case_files, vars{:});
for v = [o.var_w, o.var_wx, o.var_Q]
    if ~isfield(d, v)
        error("make_wake_topology_movie:var", "%s is not in the files of %s", v, case_label);
    end
end
L = d.L;
N = d.num_bins;
f = d.cycle_freq;
lambda = d.U / (f * L);         % x/c per wingbeat (stack_vortices_3D, x/c axis)
delay = dist * f / o.conv_speed; % convection time robot -> plane (cycles)
fprintf("%s: %d bins, f = %.3g Hz, U = %.3g m/s, %.3g c per wingbeat, %s at %.3g m (%.2f wingbeats)\n", ...
    case_label, N, f, d.U, lambda, plane_type, dist, delay);

% centre plane of each array, as the GUI ((n + 1) / 2)
centre = @(A) squeeze(A((size(A, 1) + 1) / 2, :, :, :));
y = centre(d.y);
z = centre(d.z);
W  = centre(d.(o.var_w));
WX = centre(d.(o.var_wx));
Q  = centre(d.(o.var_Q));

% trim (flowField_UI trim_bool, on by default)
iy = find(y(:,1) > trim_y(1) & y(:,1) < trim_y(2));
iz = find(z(1,:) > trim_z(1) & z(1,:) < trim_z(2));
y = y(iy, iz);   z = z(iy, iz);
W = W(iy, iz, :);   WX = WX(iy, iz, :);   Q = Q(iy, iz, :);
unc = [];
if o.unc_mask_pct > 0
    if isfield(d, "uncTot_phase_avg")
        unc = mean(centre(d.uncTot_phase_avg), 3, "omitnan");
        unc = unc(iy, iz);
    else
        warning("make_wake_topology_movie:unc", "uncTot_phase_avg missing: no uncertainty mask");
    end
end

% increasing grid vectors (plaid, for isosurface / interp3, and so the
% mirror below stacks the reflected half in order)
if y(end,1) < y(1,1)
    y = flip(y, 1); z = flip(z, 1);
    W = flip(W, 1); WX = flip(WX, 1); Q = flip(Q, 1);
    if ~isempty(unc), unc = flip(unc, 1); end
end
if z(1,end) < z(1,1)
    y = flip(y, 2); z = flip(z, 2);
    W = flip(W, 2); WX = flip(WX, 2); Q = flip(Q, 2);
    if ~isempty(unc), unc = flip(unc, 2); end
end

% mirror about the wake centreline, as flowField_UI (mirror_bool): keep
% y > mirror_center_y and shift so the first kept row is y = 0 (the
% robot's nose is on y = 0), then reflect it, skipping that row so it
% isn't doubled. The measured half is rows n_add+1:end; the reflected
% half, rows 1:n_add, is only shown from the "mirror" step on. omega_x is
% odd in y, so its reflection changes sign (as the GUI's 3D plot, cFlip).
iy_m = find(y(:,1) > mirror_c);
y = y(iy_m, :);   z = z(iy_m, :);
W = W(iy_m, :, :);   WX = WX(iy_m, :, :);   Q = Q(iy_m, :, :);
if ~isempty(unc), unc = unc(iy_m, :); end
y = y - min(y, [], 'all');
n_add = 0;
if o.mirror
    n_add = size(y, 1) - 1;
    reflect = @(A, sgn) [sgn * flip(A(2:end, :, :), 1); A];
    y = [flip(-y(2:end, :), 1); y];
    z = reflect(z, 1);
    W = reflect(W, 1);   WX = reflect(WX, -1);   Q = reflect(Q, 1);
    if ~isempty(unc), unc = reflect(unc, 1); end
end
yv = y(:,1);
zv = z(1,:)';

% median filter (filter_bool, on by default; after the mirror, as the GUI)
if o.filter
    W = nan_safe_medfilt(W);  WX = nan_safe_medfilt(WX);  Q = nan_safe_medfilt(Q);
end

% the isosurface's Q: uncertainty mask (display only, as the GUI: masked
% points get the median of Q, so no surface forms there)
Q_iso = Q;
if ~isempty(unc)
    mask = unc > o.unc_mask_pct / 100 | isnan(unc);
    mask3 = repmat(mask, 1, 1, N);
    Q_iso(mask3) = median(Q_iso(~mask3), "omitnan");
    fprintf("Uncertainty mask: %.1f%% of points hidden\n", 100 * mean(mask(:)));
end

% upsample in phase (periodic): bin j (0-based) at wing phase j / M
M = N * o.upsample;
W  = upsample_phase(W, M);
WX = upsample_phase(WX, M);
Q  = upsample_phase(Q, M);
Q_iso = upsample_phase(Q_iso, M);

%% ------------------------------------------------------------ colours
cm.w  = diverging_map(o.clim_w, 71);      % PIV_plot: colorbarpzn, 71 levels
cm.wx = diverging_map(o.clim_wx, 71);
cm.Q  = jet(71);                          % PIV_plot: jet for [0 c] limits
cm.iso = diverging_map(o.clim_wx, 127);   % setColorBar on the 3D plot
fld = struct( ...
    'w',  struct('A', W,  'cmap', cm.w,  'clim', o.clim_w,  'label', o.cb_label_w,  'caption', o.caption_w), ...
    'wx', struct('A', WX, 'cmap', cm.wx, 'clim', o.clim_wx, 'label', o.cb_label_wx, 'caption', o.caption_wx), ...
    'Q',  struct('A', Q,  'cmap', cm.Q,  'clim', o.clim_Q,  'label', o.cb_label_Q,  'caption', o.caption_Q));

%% ------------------------------------------------------------ robot
robot = [];
if o.robot
    try
        model = load_robot_model(o.robot_cad);
        robot = setup_robot(model, o, L, amp);
    catch err
        warning("make_wake_topology_movie:robot", "No robot (%s)", err.message);
    end
end

%% ------------------------------------------------------------ timeline
seg_names = ["w", "mirror", "w_to_wx", "wx", "wx_to_Q", "Q", "rotate", "build", "reveal", "hold"];
seg_dur = zeros(size(seg_names));
for i = 1:numel(seg_names)
    seg_dur(i) = o.seg.(seg_names(i));
end
if ~o.mirror
    seg_dur(seg_names == "mirror") = 0; % never selected (find picks the next segment)
end
seg_dur(seg_names == "build") = o.build_cycles * o.cycle_s; % exactly the wake's length
seg_start = [0, cumsum(seg_dur(1:end-1))];
T_total = sum(seg_dur);
t_build = seg_start(seg_names == "build");
t_build_end = t_build + o.build_cycles * o.cycle_s;

% wing phase at the plane when the build starts: chosen so the robot is
% at the top (or bottom) of its stroke then, i.e. the wake starts with a
% downstroke (upstroke), like the GUI's DU stroke order
p0 = build_start_phase(o, amp, delay);

% wing phase at the plane (cycles, unwrapped) at movie time t
    function p = wing_phase_at(t)
        if ~o.reveal_flapping && t > t_build_end
            t = t_build_end;
        end
        p = p0 + (t - t_build) / o.cycle_s;
    end

%% ------------------------------------------------------------ scene
fig = figure('Color', o.background, 'Units', 'pixels', 'Visible', o.visible, ...
    'Position', [50 50 o.resolution], 'InvertHardcopy', 'off', 'Renderer', 'opengl');
ax = axes(fig, 'Position', o.axes_pos, 'Color', o.background);
hold(ax, 'on')
axis(ax, 'off')
daspect(ax, [1 1 1])
ax.Projection = 'perspective';
ax.Clipping = 'off';

% plane (truecolor, unlit)
[Xp, Yp, Zp] = deal(zeros(size(y)), y, z);
h_plane = surface(ax, Xp, Yp, Zp, zeros([size(y) 3]), 'EdgeColor', 'none', ...
    'FaceColor', 'interp', 'FaceLighting', 'none', 'FaceAlpha', 'interp', ...
    'AlphaDataMapping', 'none', 'AlphaData', ones(size(y)), 'Clipping', 'off');

% reflected half while it unfolds in the "mirror" step: rows 1:n_add + 1
% (down to the centreline row), swung about the centreline (x = 0, y = 0)
% from on top of the measured half to its place at -y
rows_unf = 1:n_add + 1;
r_unf = -y(rows_unf, :);   % distance from the centreline
h_unf = gobjects(0);
if n_add > 0
    h_unf = surface(ax, zeros(size(r_unf)), r_unf, z(rows_unf, :), zeros([size(r_unf) 3]), ...
        'EdgeColor', 'none', 'FaceColor', 'interp', 'FaceLighting', 'none', 'FaceAlpha', 'interp', ...
        'AlphaDataMapping', 'none', 'AlphaData', zeros(size(r_unf)), 'Clipping', 'off', 'Visible', 'off');
end
show_rows = true(size(y, 1), 1);

% plane outline (GUI MERGED_3D_PLANE_COLOR / _WIDTH)
yl = [min(yv) max(yv)];  zl = [min(zv) max(zv)];
h_box = plot3(ax, zeros(1, 5), yl([1 2 2 1 1]), zl([1 1 2 2 1]), '-', ...
    'Color', o.box_color, 'LineWidth', o.box_width, 'Visible', 'off', 'Clipping', 'off');

% wake isosurface (lit)
h_iso = patch(ax, 'Faces', zeros(0, 3), 'Vertices', zeros(0, 3), ...
    'FaceVertexCData', zeros(0, 3), 'FaceColor', 'interp', 'EdgeColor', 'none', ...
    'FaceLighting', 'gouraud', 'AmbientStrength', o.iso_light(1), 'DiffuseStrength', o.iso_light(2), ...
    'SpecularStrength', o.iso_light(3), 'SpecularExponent', 15, 'BackFaceLighting', 'reverselit', ...
    'Clipping', 'off');

% robot (lit, flat)
h_robot = gobjects(0);
if ~isempty(robot)
    h_robot = patch(ax, 'Faces', robot.F, 'Vertices', robot.vertices(0), ...
        'FaceVertexCData', robot.C, 'FaceColor', 'flat', 'EdgeColor', 'none', ...
        'FaceLighting', 'flat', 'AmbientStrength', 0.45, 'DiffuseStrength', 0.7, ...
        'SpecularStrength', 0.3, 'SpecularExponent', 15, 'Clipping', 'off');
end

% scene extent (robot over a full wingbeat, plane, finished wake)
x_lo = 0;
if ~isempty(robot)
    x_lo = robot.x_range(1);
end
x_hi = lambda * o.build_cycles;
box_lo = [x_lo, yl(1), zl(1)];
box_hi = [x_hi, yl(2), zl(2)];
if ~isempty(robot)
    box_lo(2:3) = min(box_lo(2:3), robot.yz_lo);
    box_hi(2:3) = max(box_hi(2:3), robot.yz_hi);
end
pad = 0.05 * (box_hi - box_lo);
xlim(ax, [box_lo(1) box_hi(1)] + [-1 1] * pad(1))
ylim(ax, [box_lo(2) box_hi(2)] + [-1 1] * pad(2))
zlim(ax, [box_lo(3) box_hi(3)] + [-1 1] * pad(3))

% camera keyframes: head-on (plane + robot) and isometric (whole scene)
ax.CameraViewAngle = o.view_angle;
ax.CameraUpVector = [0 0 1];
head_lo = [min(x_lo, 0), box_lo(2:3)];
head_hi = [0, box_hi(2:3)];
cam_head = camera_key(o.head_on_az_el, (head_lo + head_hi) / 2, ...
    norm(head_hi(2:3) - head_lo(2:3)) / 2, o.view_angle, o.zoom_head_on);
cam_iso = camera_key(o.iso_az_el, (box_lo + box_hi) / 2, ...
    norm(box_hi - box_lo) / 2, o.view_angle, o.zoom_iso);

% one fixed light, placed relative to the isometric camera
set_camera(ax, cam_iso);
h_light = light(ax, 'Style', 'infinite');
camlight(h_light, o.light_az_el(1), o.light_az_el(2));
set_camera(ax, cam_head);

% colorbar and caption
cb = colorbar(ax, 'Position', o.colorbar_pos, 'TickLabelInterpreter', 'latex', ...
    'FontSize', o.font_size, 'Color', o.text_color);
cb.Label.Interpreter = 'latex';
cb.Label.FontSize = o.font_size + 4;
cb.Label.Rotation = 0;
cb.Label.Color = o.text_color;
cb.Label.HorizontalAlignment = 'left'; % label to the right of the ticks, inside the frame
ax.Position = o.axes_pos;   % creating the colorbar shrinks the axes
h_cap = annotation(fig, 'textbox', o.caption_pos_head_on, 'String', "", ...
    'Interpreter', 'latex', 'FontSize', o.font_size + 6, 'EdgeColor', 'none', ...
    'Color', o.text_color, 'VerticalAlignment', 'top', 'Visible', onoff(o.captions));

%% ------------------------------------------------------------ output
[out_dir, out_name] = fileparts(o.out_file);
if strlength(out_dir) == 0
    out_dir = string(o.out_dir);
end
if ~isfolder(out_dir)
    mkdir(out_dir);
end
if strlength(string(out_name)) == 0
    out_name = case_label + "_wake_topology";
    if o.preview, out_name = out_name + "_preview"; end
end
out_file = fullfile(out_dir, out_name + ".mp4");
png_dir = fullfile(out_dir, out_name + "_frames");
if o.save_png && ~isfolder(png_dir)
    mkdir(png_dir);
end
vw = VideoWriter(out_file, 'MPEG-4');
vw.FrameRate = o.fps;
vw.Quality = o.quality;
open(vw);
cleanup = onCleanup(@() safe_close(vw)); % also on an error

%% ------------------------------------------------------------ wake surface
% computed once, as flowField_UI's ensure_3D_ext / place_3D_ext (Play and
% the convection / stroke-order shifts): one isosurface over all the wake
% any frame shows, in xi = -psi * lambda (psi = phase the fluid crossed the
% plane), so each frame only slides it to x = xi + p * lambda and trims it
% to the window [0, (p - lo) * lambda]
psi_span = [p0, wing_phase_at(T_total)];
tic
wake = precompute_wake(psi_span, M, lambda, Q_iso, WX, yv, zv, o.iso_val, o.remove_small_pct);
fprintf("Wake isosurface: %d triangles over %.2f wingbeats (%.1f s)\n", ...
    size(wake.F, 1), diff(psi_span), toc);

%% ------------------------------------------------------------ render
n_frames = floor(T_total * o.fps);
render_segs = string(o.segments);
cur_cb = "";
fprintf("Rendering %d frames (%.1f s at %d fps)\n", n_frames, T_total, o.fps);
tic
written = 0;
for fi = 0:n_frames - 1
    t = fi / o.fps;
    si = find(t >= seg_start, 1, 'last');
    seg = seg_names(si);
    s = min(max((t - seg_start(si)) / seg_dur(si), 0), 1);
    if ~isempty(render_segs) && ~ismember(seg, render_segs)
        continue
    end
    p = wing_phase_at(t);

    % ---- plane field and its colour, caption, colorbar
    [fa, fb, mix] = plane_fields(seg, s);
    rgb = field_rgb(fld.(fa), p, M);
    if mix > 0
        rgb = (1 - mix) * rgb + mix * field_rgb(fld.(fb), p, M);
    end
    alpha_plane = 1;
    switch seg
        case "reveal", alpha_plane = 1 - ease(min(s / o.plane_fade_frac, 1));
        case "hold",   alpha_plane = 0;
    end
    shown = fa;
    if mix >= 0.5, shown = fb; end
    valid = double(~isnan(sample_phase(fld.(shown).A, p, M)));
    % the measured half only, until the reflected half has unfolded
    show_rows(:) = true;
    if ismember(seg, ["w", "mirror"])
        show_rows(1:n_add) = false;
    end
    set(h_plane, 'CData', rgb, 'AlphaData', valid .* show_rows * alpha_plane, ...
        'Visible', onoff(alpha_plane > 0));
    if seg == "mirror" && n_add > 0
        th = pi * ease(s);
        sw = 1;
        if o.mirror_swing == "upstream", sw = -1; end
        fade = min(1, s / o.mirror_fade_frac);
        set(h_unf, 'XData', sw * r_unf * sin(th), 'YData', r_unf * cos(th), ...
            'CData', rgb(rows_unf, :, :), 'AlphaData', valid(rows_unf, :) * fade, 'Visible', 'on');
    else
        set(h_unf, 'Visible', 'off');
    end

    if ismember(seg, ["reveal", "hold"])
        cb_key = "iso";
        set(h_cap, 'String', o.caption_reveal);
    elseif seg == "build"
        cb_key = "Q";
        set(h_cap, 'String', o.caption_build);
    elseif seg == "mirror"
        cb_key = "w";
        set(h_cap, 'String', o.caption_mirror);
    else
        cb_key = shown;
        cap = fld.(shown).caption;
        if seg == "w_to_wx" && shown == "w" && o.mirror
            cap = o.caption_mirror; % straight from the mirror title to omega_x's
        end
        set(h_cap, 'String', cap);
    end
    % the frozen-flow title is held a little longer than the build itself:
    % from caption_build_lead s before it (end of the camera move) to
    % caption_build_lag s after it (start of the reveal)
    if t >= t_build - o.caption_build_lead && t < t_build_end + o.caption_build_lag
        set(h_cap, 'String', o.caption_build);
    end
    if cb_key ~= cur_cb
        if cb_key == "iso"
            ax.Colormap = cm.iso;  clim(ax, o.clim_wx);  cb.Label.String = o.cb_label_wx;
        else
            ax.Colormap = fld.(cb_key).cmap;  clim(ax, fld.(cb_key).clim);
            cb.Label.String = fld.(cb_key).label;
        end
        cur_cb = cb_key;
    end

    % ---- plane outline
    h_box.Visible = onoff(ismember(seg, ["reveal", "hold"]));

    % ---- wake
    if ismember(seg, ["build", "reveal", "hold"])
        lo = max(p0, p - o.build_cycles);
        [Fw, Vw, Cw, Nw] = place_wake(wake, p, lo, lambda);
        c_mix = 0;
        switch seg
            case "reveal", c_mix = ease(s);
            case "hold",   c_mix = 1;
        end
        rgb_iso = repmat(o.iso_grey, size(Vw, 1), 1);
        if c_mix > 0 && ~isempty(Vw)
            rgb_iso = (1 - c_mix) * rgb_iso + c_mix * values_to_rgb(Cw, cm.iso, o.clim_wx);
        end
        set(h_iso, 'Vertices', Vw, 'Faces', Fw, 'FaceVertexCData', rgb_iso, 'VertexNormals', Nw);
        % lit while grey; the lighting goes as the omega_x colours come in
        % (all ambient = the colours as they are, then lighting off, as
        % the GUI's unlit 3D plot)
        if c_mix >= 1
            h_iso.FaceLighting = 'none';
        else
            set(h_iso, 'FaceLighting', 'gouraud', ...
                'AmbientStrength', o.iso_light(1) + (1 - o.iso_light(1)) * c_mix, ...
                'DiffuseStrength', o.iso_light(2) * (1 - c_mix), ...
                'SpecularStrength', o.iso_light(3) * (1 - c_mix));
        end
    else
        set(h_iso, 'Faces', zeros(0, 3), 'Vertices', zeros(0, 3), 'FaceVertexCData', zeros(0, 3));
    end

    % ---- robot: wings at the phase the fluid at the plane was shed
    if ~isempty(h_robot)
        h_robot.Vertices = robot.vertices(p - delay);
        a = 1;
        if ismember(seg, ["w", "mirror", "w_to_wx", "wx", "wx_to_Q", "Q"])
            a = o.robot_alpha_head_on;
        elseif seg == "rotate"
            a = o.robot_alpha_head_on + (1 - o.robot_alpha_head_on) * ease(s);
        end
        h_robot.FaceAlpha = a;
    end

    % ---- caption position: above the plane head-on, moving down to just
    % above the wake as the camera turns
    switch seg
        case "rotate"
            h_cap.Position = o.caption_pos_head_on + ...
                (o.caption_pos_iso - o.caption_pos_head_on) * ease(s);
        case {"build", "reveal", "hold"}
            h_cap.Position = o.caption_pos_iso;
        otherwise
            h_cap.Position = o.caption_pos_head_on;
    end

    % ---- camera
    switch seg
        case "rotate"
            set_camera(ax, lerp_camera(cam_head, cam_iso, ease(s)));
        case {"build", "reveal"}
            set_camera(ax, cam_iso);
        case "hold"
            c = cam_iso;
            c.az = c.az + o.hold_orbit_deg * ease(s);
            set_camera(ax, c);
        otherwise
            set_camera(ax, cam_head);
    end

    % ---- frame
    drawnow
    img = grab_frame(fig, o.resolution);
    writeVideo(vw, img);
    if o.save_png
        imwrite(img, fullfile(png_dir, sprintf("frame_%05d.png", fi)));
    end
    written = written + 1;
    if mod(written, 50) == 0
        fprintf("  frame %d / %d (%s), %.0f s\n", fi + 1, n_frames, seg, toc);
    end
end
safe_close(vw);
fprintf("Wrote %s (%d frames, %.0f s)\n", out_file, written, toc);
if ~o.keep_figure
    close(fig);
end

%% ------------------------------------------------------------ nested helpers
    % plane fields of a segment: A, B and how far it has faded from A to B
    function [fa, fb, mix] = plane_fields(seg, s)
        fb = "";
        mix = 0;
        switch seg
            case "w",       fa = "w";
            case "mirror",  fa = "w";
            case "w_to_wx", fa = "w";  fb = "wx"; mix = ease(s);
            case "wx",      fa = "wx";
            case "wx_to_Q", fa = "wx"; fb = "Q";  mix = ease(s);
            otherwise,      fa = "Q";
        end
        if fb == "", fb = fa; end
    end
end

%% ===================================================================== defaults
function o = default_options()
% --- timing
o.fps = 30;
o.cycle_s = 2.5;             % movie seconds per wingbeat (slow motion)
o.build_cycles = 1;          % wingbeats of wake built (GUI "num_cycles"); also sets the build's length
o.seg = struct('w', 3, 'mirror', 3, 'w_to_wx', 1, 'wx', 3, 'wx_to_Q', 1, 'Q', 3, ...
    'rotate', 3, 'build', NaN, 'reveal', 3, 'hold', 5); % s; build = build_cycles * cycle_s
o.build_start = "top";       % robot at the "top" / "bottom" of its stroke when the build starts, or a wing phase (cycles)
o.reveal_flapping = true;    % keep flapping (wake keeps convecting) after the build; false freezes it
o.plane_fade_frac = 0.6;
o.mirror_fade_frac = 0.15;   % part of "mirror" over which the reflected half fades in
o.mirror_swing = "downstream"; % the reflected half swings out "downstream" (away from the robot) or "upstream"     % part of "reveal" over which the plane fades out
o.hold_orbit_deg = 0;        % camera azimuth change over "hold"
o.segments = strings(0);     % render only these segments ([] = all)
% --- data (flowField_UI defaults)
o.var_w = "w_phase_avg";
o.var_wx = "vortX_phase_avg";
o.var_Q = "Q";               % iso variable "|Q|"
o.iso_val = 0.05;            % Q_ISO_DEFAULT
o.filter = true;             % filter_bool
o.unc_mask_pct = 3;          % unc_mask_thresh (% of U), 0 = off
o.remove_small_pct = 1;      % REMOVE_SMALL_DEFAULT, 0 = off
o.trim_y = [];               % [] = the source mode's trim box (NEW/OLD_FLAPPER_TRIM_*)
o.trim_z = [];
o.mirror = true;             % mirror about the centreline (GUI mirror_bool) from the "mirror" step on
o.mirror_center_y = [];      % [] = the source mode's (NEW/OLD_FLAPPER_MIRROR_CENTER_Y)
o.conv_speed = plane_downstream_dists("conv_speed");
o.upsample = 4;              % phase upsampling (interpft); 1 = the GUI's bins
o.clim_w = [-0.2 0.2];       % mean_clims
o.clim_wx = [-1 1];
o.clim_Q = [0 0.1];
% --- robot (keep in sync with flowField_UI ROBOT_*)
o.robot = true;
o.robot_cad = struct('dir', "F:\CAD", 'body_file', "Calimero_body.STL", ...
    'wing_files', ["left_wing.STL", "right_wing.STL"], 'rod_files', ["rod1.STL", "rod2.STL"], ...
    'cad_to_tunnel', [-1 0 0; 0 0 1; 0 1 0], 'up_dir', [0 0 1], 'max_faces', 5e4);
o.robot_phi_export = 0;
o.robot_offset_mm = [0 0 0];
o.robot_pitch_deg = 10;
o.robot_offset_c = [0 0 -0.25];
o.robot_nose_on_centreline = true;
o.robot_gap_c = 0.5;
o.robot_body_color = [0.6 0.6 0.6];
o.robot_wing_color = [0.06 0.06 0.06];
o.robot_alpha_head_on = 1;   % < 1 to see the plane through the robot in the head-on view
% --- look
o.resolution = [1920 1080];
o.axes_pos = [0 0 0.8 1];            % normalized figure position of the 3D axes
o.colorbar_pos = [0.74 0.2 0.016 0.6]; % colorbar (over the axes' empty right side); its label sits to its right
o.caption_pos_head_on = [0.16 0.88 0.7 0.09]; % caption textbox (top-left anchored) in the head-on view
o.caption_pos_iso = [0.16 0.72 0.7 0.09];     % ... and in the isometric view (moves over "rotate")
o.background = [1 1 1];
o.text_color = [0 0 0];
o.font_size = 16;
o.captions = true;
o.box_color = [0.30 0.69 0.20];  % MERGED_3D_PLANE_COLOR
o.box_width = 3;
o.iso_grey = [0.72 0.72 0.75];
o.iso_light = [0.4 0.7 0.3]; % grey isosurface: ambient, diffuse, specular strength
o.view_angle = 12;               % deg (camera view angle, fixed)
o.head_on_az_el = [0 0];         % camera direction: az = 0, el = 0 looks downstream from upstream
o.iso_az_el = [60 22];           % az from upstream towards -y, el above
o.zoom_head_on = 1;              % > 1 moves the camera closer
o.zoom_iso = 1;
o.light_az_el = [30 30];         % relative to the isometric camera
o.cb_label_w = "\boldmath$\frac{w}{U_{\infty}}$";
o.cb_label_wx = "\boldmath$\frac{\omega_x c}{U_{\infty}}$";
o.cb_label_Q = "\boldmath$\frac{Q c^2}{U_{\infty}^2}$";
o.caption_w = "Downwash $w$ in the imaging plane";
o.caption_mirror = "Mirrored about the centerline to obtain the wake of both wings";
o.caption_wx = "Streamwise vorticity $\omega_x$";
o.caption_Q = "$Q$-criterion";
o.caption_build_lead = 1.5;  % s the frozen-flow title shows before the build starts
o.caption_build_lag = 1.5;   % s it stays after the build ends
o.caption_build = "Frozen flow: $x = U_{\infty} t$ stacks the plane into a 3D wake";
o.caption_reveal = "$Q$ isosurfaces colored by $\omega_x$";
% --- output
o.out_dir = "C:\Users\rgissler\Documents\DFD 2026"; % where the .mp4 (and PNG frames) go; made if missing
o.out_file = "";             % "" = <case>_wake_topology.mp4 in out_dir; a name with a folder overrides out_dir
o.quality = 95;
o.save_png = false;          % also write every frame as a PNG
o.visible = 'on';            % 'off' renders without showing the figure
o.keep_figure = false;
o.preview = false;
o.preview_fps = 15;
o.preview_resolution = [960 540];
end

function o = parse_options(o, varargin)
if mod(numel(varargin), 2) ~= 0
    error("make_wake_topology_movie:args", "Options must be name-value pairs");
end
for k = 1:2:numel(varargin)
    name = char(varargin{k});
    if ~isfield(o, name)
        error("make_wake_topology_movie:args", "Unknown option '%s'", name);
    end
    if isstruct(o.(name)) && isstruct(varargin{k+1})
        fn = fieldnames(varargin{k+1});  % partial structs (e.g. seg) merge
        for j = 1:numel(fn)
            o.(name).(fn{j}) = varargin{k+1}.(fn{j});
        end
    else
        o.(name) = varargin{k+1};
    end
end
end

%% ===================================================================== case
function [plane_type, dist, trim_y, trim_z, mirror_c] = plane_info(stem, o)
% plane type from the stem's prefix, its distance from the robot
% (plane_downstream_dists, as flowField_UI) and the source mode's trim box
new_types = ["x1"; "x2"; "x3"; "x4"; "x5"; "MPS"];
old_types = ["UP_two_flexible"; "UP_one_flexible"; "flexible"]; % longest first
new_d = plane_downstream_dists("new");
old_d = plane_downstream_dists("old");              % flexible, UP_one, UP_two
old_d = old_d([3 2 1]);
plane_type = "";
for k = 1:numel(new_types)
    if startsWith(stem, new_types(k) + "_")
        plane_type = new_types(k);  dist = new_d(k);
        trim_y = [-2.4 2.8];  trim_z = [-2.9 3.1];  % NEW_FLAPPER_TRIM_*
        mirror_c = -2.06;                           % NEW_FLAPPER_MIRROR_CENTER_Y
    end
end
for k = 1:numel(old_types)
    if plane_type == "" && startsWith(stem, old_types(k) + "_")
        plane_type = old_types(k);  dist = old_d(k);
        trim_y = [-2.26 2];  trim_z = [-2.36 2.55]; % OLD_FLAPPER_TRIM_*
        mirror_c = -2.26;                           % OLD_FLAPPER_MIRROR_CENTER_Y
    end
end
if plane_type == ""
    error("make_wake_topology_movie:plane", "Can't tell the imaging plane of '%s'", stem);
end
if ~isempty(o.trim_y), trim_y = o.trim_y; end
if ~isempty(o.trim_z), trim_z = o.trim_z; end
if ~isempty(o.mirror_center_y), mirror_c = o.mirror_center_y; end
end

function p0 = build_start_phase(o, amp, delay)
% plane phase at the start of the build: robot wing phase o.build_start
% (or the top / bottom of the stroke) plus the convection delay, the
% first such phase >= 0
if isnumeric(o.build_start)
    pr = o.build_start;
else
    ph = linspace(0, 1, 2001);
    [dd, rr] = get_calimero_dims(amp);
    phi = calimero_mechanism(2 * pi * ph, dd, rr);
    if o.build_start == "bottom"
        [~, i] = min(phi);
    else
        [~, i] = max(phi);
    end
    pr = ph(i);
end
p0 = mod(pr + delay, 1);
end

%% ===================================================================== data
function A = nan_safe_medfilt(A)
% as flowField_UI.nan_safe_medfilt: NaNs filled with their nearest
% neighbours for the filter, then put back
nan_mask = isnan(A);
if any(nan_mask, "all")
    for dim = 1:ndims(A)
        A = fillmissing(A, "nearest", dim);
    end
    A(isnan(A)) = 0;
end
if ismatrix(A)
    A = medfilt2(A);
else
    A = medfilt3(A);
end
A(nan_mask) = NaN;
end

function B = upsample_phase(A, M)
% periodic Fourier interpolation along phase (dim 3) to M bins; points
% that are NaN in any bin stay NaN
N = size(A, 3);
if M == N
    B = A;
    return
end
nan_any = any(isnan(A), 3);
if any(isnan(A), "all")
    A = fillmissing(A, "nearest", 3);
    A(isnan(A)) = 0;
end
B = interpft(A, M, 3);
B(repmat(nan_any, 1, 1, M)) = NaN;
end

function V = sample_phase(A, psi, M)
% A (y, z, M bins, bin j at phase j/M) at phases psi (cycles), linear in
% phase between bins (as flowField_UI.phase_interp)
kf = mod(psi(:)' * M, M);
k0 = floor(kf);
w = kf - k0;
k0 = mod(k0, M);
k1 = mod(k0 + 1, M);
V = A(:,:,k0 + 1) .* reshape(1 - w, 1, 1, []) + A(:,:,k1 + 1) .* reshape(w, 1, 1, []);
on_bin = w == 0;
V(:,:,on_bin) = A(:,:,k0(on_bin) + 1);
end

function W = precompute_wake(psi_span, M, lambda, Q, WX, yv, zv, iso, min_pct)
% Q isosurface of the wake shed over phases psi_span (cycles, plus a bin
% each side), on the M-bin phase grid, with x as xi = -psi * lambda (so a
% frame at plane phase p puts it at x = xi + p * lambda: the fluid that
% crossed the plane at psi is (p - psi) lambda downstream). omega_x and
% normals per vertex, Remove Small applied once (as ensure_3D_ext).
j = (ceil(psi_span(2) * M) + 1:-1:floor(psi_span(1) * M) - 1);  % descending psi
psi = j / M;
xi = -psi * lambda;                                             % ascending
Vq = permute(sample_phase(Q, psi, M), [1 3 2]);                 % y, x, z
Vc = permute(sample_phase(WX, psi, M), [1 3 2]);
[X, Y, Z] = meshgrid(xi, yv, zv);
s = isosurface(X, Y, Z, Vq, iso);
W.F = s.faces;
V = s.vertices;
if isempty(W.F)
    W.F = zeros(0, 3);  V = zeros(0, 3);
end
if min_pct > 0
    W.F = despeckle_faces(W.F, min_pct);
end
W.xi = V(:,1);
W.YZ = V(:,2:3);
W.C = interp3(X, Y, Z, Vc, V(:,1), V(:,2), V(:,3));
W.N = isonormals(X, Y, Z, Vq, V);
end

function [F, V, C, Nrm] = place_wake(W, p, lo, lambda)
% the precomputed wake at plane phase p, showing what was shed since lo:
% slid to x = xi + p * lambda, faces wholly outside [0, x_end] dropped and
% the vertices of those crossing an end clamped onto it (a clean cut at
% the plane and at the downstream end, as the GUI's axes clipping), then
% only the vertices still used kept
F = zeros(0, 3);  V = zeros(0, 3);  C = zeros(0, 1);  Nrm = zeros(0, 3);
x_end = (p - lo) * lambda;
if x_end <= 0 || isempty(W.F)
    return
end
x = W.xi + p * lambda;
fx = reshape(x(W.F), size(W.F));
keep = any(fx >= 0, 2) & any(fx <= x_end, 2);
if ~any(keep)
    return
end
Fk = W.F(keep, :);
used = false(numel(x), 1);
used(Fk) = true;
idx = find(used);
map = zeros(numel(x), 1);
map(idx) = 1:numel(idx);
F = reshape(map(Fk), size(Fk));
V = [min(max(x(idx), 0), x_end), W.YZ(idx, :)];
C = W.C(idx);
Nrm = W.N(idx, :);
end

function faces = despeckle_faces(faces, min_pct)
% as flowField_UI.despeckle_faces (Remove Small)
if isempty(faces) || min_pct <= 0
    return
end
n_verts = max(faces(:));
G = graph([faces(:,1); faces(:,2); faces(:,3)], ...
          [faces(:,2); faces(:,3); faces(:,1)], [], n_verts);
piece = conncomp(G);
face_piece = piece(faces(:,1));
n_faces = accumarray(face_piece(:), 1);
keep_piece = n_faces >= min_pct / 100 * max(n_faces);
faces = faces(keep_piece(face_piece), :);
end

%% ===================================================================== colour
function cmap = diverging_map(clims, n)
% colorbarpzn's map for these limits (as PIV_plot / setColorBar), without
% drawing a colorbar
try
    cmap = colorbarpzn(clims(1), clims(2), 'level', n, 'off');
catch
    t = linspace(-1, 1, n)';
    cmap = [min(1, 1 + t), 1 - abs(t), min(1, 1 - t)]; % blue - white - red
    cmap(:, [1 3]) = max(cmap(:, [1 3]), 0);
end
end

function rgb = values_to_rgb(v, cmap, clims)
% values -> colormap rows (clipped to clims, nearest level); NaN -> grey
n = size(cmap, 1);
k = round((min(max(v, clims(1)), clims(2)) - clims(1)) / diff(clims) * (n - 1)) + 1;
bad = isnan(k);
k(bad) = 1;
rgb = cmap(k(:), :);
rgb(bad(:), :) = 0.8;
rgb = reshape(rgb, [size(v), 3]);
if isvector(v) && size(v, 2) == 1
    rgb = reshape(rgb, [numel(v), 3]);
end
end

function rgb = field_rgb(fld, p, M)
rgb = values_to_rgb(sample_phase(fld.A, p, M), fld.cmap, fld.clim);
end

%% ===================================================================== robot
function R = setup_robot(model, o, L, amp)
% robot in the 3D plot's frame (chords, tail robot_gap_c upstream of the
% plane at x = 0), as flowField_UI.draw_robot in "front" mode. The x shift
% is fixed from the midstroke pose so the body doesn't jitter as the wings
% move.
[dd, rr] = get_calimero_dims(amp);
pivot = (model.hinge(1).p + model.hinge(2).p) / 2;
c = cosd(o.robot_pitch_deg);  sn = sind(o.robot_pitch_deg);
Ry = [c 0 sn; 0 1 0; -sn 0 c];
nose_y = 0;
if o.robot_nose_on_centreline && isfield(model, 'nose')
    nose_y = model.nose(2);
end
    function V = place(dphi)
        [~, V] = robot_posed_mesh(model, dphi);
        if o.robot_pitch_deg ~= 0
            V = (V - pivot) * Ry.' + pivot;
        end
        V(:,2) = V(:,2) - nose_y;
        V = (V + o.robot_offset_mm) / (1000 * L) + o.robot_offset_c;
    end
[F, V0] = robot_posed_mesh(model, -o.robot_phi_export);
V0 = place(-o.robot_phi_export);
x_shift = -max(V0(:,1)) - o.robot_gap_c;

R.F = F;
R.vertices = @(phase) shifted(place(rad2deg(calimero_mechanism(2 * pi * phase, dd, rr)) - o.robot_phi_export));
    function V = shifted(V)
        V(:,1) = V(:,1) + x_shift;
    end
nf = arrayfun(@(P) size(P.F, 1), model.parts);
is_wing = repelem([model.parts.moves] > 0, nf)';
R.C = repmat(o.robot_body_color, numel(is_wing), 1);
R.C(is_wing, :) = repmat(o.robot_wing_color, nnz(is_wing), 1);

% extent over a wingbeat
lo = inf(1, 3);  hi = -inf(1, 3);
for ph = linspace(0, 1, 9)
    Vt = R.vertices(ph);
    lo = min(lo, min(Vt));  hi = max(hi, max(Vt));
end
R.x_range = [lo(1) hi(1)];
R.yz_lo = lo(2:3);
R.yz_hi = hi(2:3);
end

%% ===================================================================== camera
function c = camera_key(az_el, target, radius, view_angle, zoom)
% camera looking at target from direction (az, el): az = el = 0 is from
% upstream (-x), az > 0 swings towards -y, el > 0 above; the distance
% fits a sphere of the given radius in the view angle
c.az = az_el(1);
c.el = az_el(2);
c.target = target(:)';
c.dist = radius / tand(view_angle / 2) / zoom;
end

function c = lerp_camera(a, b, s)
c.az = a.az + (b.az - a.az) * s;
c.el = a.el + (b.el - a.el) * s;
c.target = a.target + (b.target - a.target) * s;
c.dist = a.dist * (b.dist / a.dist) ^ s;   % geometric, so the zoom feels even
end

function set_camera(ax, c)
dir = [-cosd(c.el) * cosd(c.az), -cosd(c.el) * sind(c.az), sind(c.el)];
ax.CameraTarget = c.target;
ax.CameraPosition = c.target + c.dist * dir;
ax.CameraUpVector = [0 0 1];
end

%% ===================================================================== misc
function safe_close(vw)
try
    close(vw);
catch
end
end

function s = ease(s)
s = 3 * s.^2 - 2 * s.^3;   % smoothstep
end

function str = onoff(tf)
if tf, str = 'on'; else, str = 'off'; end
end

function img = grab_frame(fig, res)
% figure as an RGB image of exactly res = [width height] pixels (print
% renders off screen, so it works with an invisible figure; resized if the
% display scaling changes the size)
img = print(fig, '-RGBImage', '-r0');
if size(img, 1) ~= res(2) || size(img, 2) ~= res(1)
    img = imresize(img, [res(2) res(1)]);
end
end
