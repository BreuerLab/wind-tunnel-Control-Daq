% robot_flap_test.m
% Standalone test: 3D rendering of Calimero flapping its wings, from the
% CAD parts exported as STL, before this goes into flowField_UI.
%
% The wing angle follows the quick-return mechanism, calimero_mechanism /
% get_calimero_dims (Calimero Properties), so the short upstroke and its
% change with amplitude come out as in the experiments. Each wing is a
% rigid body rotating about its shoulder axis, found from rod1 / rod2
% (taken to be the shoulder rods: each one's long direction through its
% centroid, matched to the nearer wing). Wing bending isn't modelled.
%
% Assumes the STLs were exported in one shared coordinate system (the
% parts line up when loaded together). They are rotated on loading from
% the CAD axes into the wind tunnel frame of the wake plots (CAD_TO_TUNNEL):
% x downstream (the robot's nose points to -x), y spanwise, z up. Run it once and
% look at the check figure (figure 1): the shoulder axes should run along
% the rods and the wingtip markers should sit at the tips. Then the
% animation (figure 2) plays NUM_CYCLES wingbeats.
%
% theta (motor angle) = 2*pi*t/T, theta = 0 the encoder zero: wing at
% midstroke moving up (as calimero_mechanism). phi > 0: wing above
% horizontal.

clear
close all

%% Settings
CAD_DIR = "F:\CAD";
BODY_FILE  = "Calimero_body.STL";
WING_FILES = ["left_wing.STL", "right_wing.STL"];
ROD_FILES  = ["rod1.STL", "rod2.STL"];

AMP = 20;              % wingbeat amplitude (deg): 10, 20 or 30 (get_calimero_dims)
PHI_EXPORT = 0;        % wing angle (deg) the wings were exported at (0 = midstroke, horizontal)
% CAD axes -> tunnel axes: rows are tunnel x, y, z in CAD coordinates.
% CAD: x chordwise with the nose at +x, y vertical, z spanwise, so tunnel
% x (downstream) = -x_CAD, y (span) = z_CAD, z (up) = y_CAD (a proper
% rotation, det = +1)
CAD_TO_TUNNEL = [-1 0 0; 0 0 1; 0 1 0];
UP_DIR = [0 0 1];      % "up" in the tunnel frame (positive phi raises the wingtip along it)
ROD_MOVES_WITH_WING = false; % true: the rods rotate with their wing (else drawn with the body)

NUM_CYCLES = 3;        % wingbeats to animate
FRAMES_PER_CYCLE = 120;
FPS = 30;
MAX_FACES = 2e5;       % per part; larger meshes are reduced (reducepatch) for smooth rotation
SAVE_VIDEO = false;
VIDEO_FILE = "robot_flap_test.mp4";

BODY_COLOR = [0.55 0.55 0.58];
WING_COLOR = [0.85 0.85 0.88];
ROD_COLOR  = [0.25 0.25 0.25];

this_dir = fileparts(mfilename('fullpath'));
addpath(fullfile(this_dir, "..", "Calimero Properties")) % calimero_mechanism, get_calimero_dims

%% Load the parts
assert(abs(det(CAD_TO_TUNNEL) - 1) < 1e-9, "CAD_TO_TUNNEL must be a rotation (det = +1)")
body = load_part(fullfile(CAD_DIR, BODY_FILE), MAX_FACES, CAD_TO_TUNNEL);
for k = 1:2
    wings(k) = load_part(fullfile(CAD_DIR, WING_FILES(k)), MAX_FACES, CAD_TO_TUNNEL); %#ok<SAGROW>
    rods(k)  = load_part(fullfile(CAD_DIR, ROD_FILES(k)), MAX_FACES, CAD_TO_TUNNEL); %#ok<SAGROW>
end

all_V = [body.V; vertcat(wings.V); vertcat(rods.V)];
extent = max(all_V) - min(all_V);
fprintf("Robot extent (mm): %.4g (streamwise) x %.4g (span) x %.4g (vertical)\n", extent);
if max(extent) > 50
    disp("  (looks like mm)")
elseif max(extent) < 1
    disp("  (looks like m)")
end

%% Shoulder axes: one per rod, matched to the nearer wing
axes_fit = struct('p', {}, 'u', {}, 'len', {}, 'aspect', {});
for k = 1:2
    axes_fit(k) = fit_rod_axis(rods(k).V);
    fprintf("%s: axis through (%.4g, %.4g, %.4g), direction (%.3f, %.3f, %.3f), length %.4g, length/width %.1f\n", ...
        ROD_FILES(k), axes_fit(k).p, axes_fit(k).u, axes_fit(k).len, axes_fit(k).aspect);
    if axes_fit(k).aspect < 3
        warning("%s is not much longer than it is wide: its axis direction is uncertain", ROD_FILES(k));
    end
end

% rod -> wing: the rod whose axis passes closest to the wing's vertices
dist = zeros(2, 2); % dist(wing, rod)
for w = 1:2
    for k = 1:2
        dist(w, k) = min(dist_to_line(wings(w).V, axes_fit(k).p, axes_fit(k).u));
    end
end
if dist(1,1) + dist(2,2) <= dist(1,2) + dist(2,1)
    rod_of_wing = [1 2];
else
    rod_of_wing = [2 1];
end
for w = 1:2
    fprintf("%s hinges on %s (closest approach %.3g)\n", WING_FILES(w), ROD_FILES(rod_of_wing(w)), ...
        dist(w, rod_of_wing(w)));
end

% wingtip (vertex farthest from the axis); sign of each axis so positive
% rotation raises the tip along UP_DIR
UP_DIR = UP_DIR(:)' / norm(UP_DIR);
hinge = struct('p', {}, 'u', {}, 'tip', {});
for w = 1:2
    a = axes_fit(rod_of_wing(w));
    [~, i_tip] = max(dist_to_line(wings(w).V, a.p, a.u));
    tip = wings(w).V(i_tip, :);
    u = a.u;
    tip_moved = rotate_about(tip, a.p, u, deg2rad(1));
    if dot(tip_moved - tip, UP_DIR) < 0
        u = -u;
    end
    hinge(w) = struct('p', a.p, 'u', u, 'tip', tip);
    elev = asind(dot(tip - a.p, UP_DIR) / norm(tip - a.p));
    fprintf("%s tip at (%.4g, %.4g, %.4g), %.1f deg above horizontal in the export (PHI_EXPORT = %g)\n", ...
        WING_FILES(w), tip, elev, PHI_EXPORT);
end

%% Wing angle over a wingbeat (quick-return mechanism)
[d, r] = get_calimero_dims(AMP);
t_T = (0:FRAMES_PER_CYCLE-1) / FRAMES_PER_CYCLE;
phi = rad2deg(calimero_mechanism(2*pi*t_T, d, r)); % deg
[~, i_max] = max(phi);
[~, i_min] = min(phi);
up_frac = mod(t_T(i_max) - t_T(i_min), 1);
fprintf("Amplitude %d deg: phi from %.1f to %.1f deg, upstroke %.0f%% / downstroke %.0f%% of the cycle\n", ...
    AMP, min(phi), max(phi), 100*up_frac, 100*(1 - up_frac));

%% Check figure: parts, shoulder axes, wingtips
fig1 = figure(1);
fig1.Name = "Robot check";
ax1 = axes(fig1);
draw_part(ax1, body, BODY_COLOR);
for k = 1:2
    draw_part(ax1, wings(k), WING_COLOR);
    draw_part(ax1, rods(k), ROD_COLOR);
end
hold(ax1, 'on')
L = 0.6 * max(extent);
for w = 1:2
    h = hinge(w);
    seg = [h.p - L/2*h.u; h.p + L/2*h.u];
    plot3(ax1, seg(:,1), seg(:,2), seg(:,3), 'r-', 'LineWidth', 2)
    quiver3(ax1, h.p(1), h.p(2), h.p(3), L/4*h.u(1), L/4*h.u(2), L/4*h.u(3), 0, ...
        'r', 'LineWidth', 2, 'MaxHeadSize', 0.5)
    plot3(ax1, h.tip(1), h.tip(2), h.tip(3), 'bo', 'MarkerSize', 10, 'LineWidth', 2)
    text(ax1, h.tip(1), h.tip(2), h.tip(3), "  " + WING_FILES(w), 'Interpreter', 'none')
end
hold(ax1, 'off')
style_axes(ax1)
title(ax1, "Check: red = shoulder axes (arrow: +rotation raises the tip), blue = wingtips")

%% Animation
fig2 = figure(2);
fig2.Name = "Robot flapping";
fig2.Color = 'w';
ax = axes(fig2, 'Position', [0.05 0.25 0.9 0.7]);
draw_part(ax, body, BODY_COLOR);
wing_tf = gobjects(1, 2);
for w = 1:2
    wing_tf(w) = hgtransform(ax);
    draw_part(wing_tf(w), wings(w), WING_COLOR);
    if ROD_MOVES_WITH_WING
        draw_part(wing_tf(w), rods(rod_of_wing(w)), ROD_COLOR);
    else
        draw_part(ax, rods(rod_of_wing(w)), ROD_COLOR);
    end
end
style_axes(ax)
% fix the limits to the full stroke so the view doesn't jump
lims = stroke_limits([body.V; vertcat(rods.V)], wings, hinge, phi - PHI_EXPORT);
xlim(ax, lims(1,:)); ylim(ax, lims(2,:)); zlim(ax, lims(3,:));

% wing angle trace with the current position
ax_phi = axes(fig2, 'Position', [0.1 0.06 0.8 0.13]);
plot(ax_phi, [t_T, 1], [phi, phi(1)], 'k-', 'LineWidth', 1.5)
hold(ax_phi, 'on')
marker = plot(ax_phi, 0, phi(1), 'ro', 'MarkerFaceColor', 'r');
hold(ax_phi, 'off')
xlabel(ax_phi, "t/T")
ylabel(ax_phi, "\phi (deg)")
xlim(ax_phi, [0 1])
grid(ax_phi, 'on')

if SAVE_VIDEO
    vid = VideoWriter(VIDEO_FILE, 'MPEG-4');
    vid.FrameRate = FPS;
    open(vid);
end
for c = 1:NUM_CYCLES
    for n = 1:FRAMES_PER_CYCLE
        if ~isvalid(fig2)
            return
        end
        for w = 1:2
            wing_tf(w).Matrix = hinge_transform(hinge(w), deg2rad(phi(n) - PHI_EXPORT));
        end
        marker.XData = t_T(n);
        marker.YData = phi(n);
        title(ax, sprintf("Amplitude %d deg,  t/T = %.2f,  \\phi = %.1f deg", AMP, t_T(n), phi(n)))
        drawnow
        if SAVE_VIDEO
            writeVideo(vid, getframe(fig2));
        else
            pause(1/FPS);
        end
    end
end
if SAVE_VIDEO
    close(vid);
    fprintf("Saved %s\n", VIDEO_FILE);
end

%% Local functions

% STL -> faces / vertices, reduced to max_faces if larger, rotated into
% the tunnel frame (R: rows are the tunnel axes in CAD coordinates)
function part = load_part(file, max_faces, R)
    if ~isfile(file)
        error("Not found: %s", file);
    end
    TR = stlread(file);
    F = TR.ConnectivityList;
    V = TR.Points;
    n0 = size(F, 1);
    if n0 > max_faces
        [F, V] = reducepatch(F, V, max_faces);
        fprintf("%s: %d faces, reduced to %d\n", file, n0, size(F, 1));
    else
        fprintf("%s: %d faces\n", file, n0);
    end
    lo = min(V, [], 1);
    fprintf("  lowest corner (%.4g, %.4g, %.4g)\n", lo);
    if all(abs(lo) < 1e-3 * max(max(V, [], 1) - lo))
        warning("%s starts at the origin: probably shifted to positive space on export " + ...
            "(tick ""Do not translate STL output data to positive space""), so it won't line up with the other parts", file);
    end
    V = V * R.';
    part = struct('F', F, 'V', V);
end

% Axis of a rod: through the centroid along the direction of largest
% spread (first principal component of its vertices)
function a = fit_rod_axis(V)
    p = mean(V, 1);
    [~, S, W] = svd(V - p, 'econ');
    u = W(:, 1)';
    proj = (V - p) * W;
    len = max(proj(:,1)) - min(proj(:,1));
    width = max(max(proj(:,2)) - min(proj(:,2)), max(proj(:,3)) - min(proj(:,3)));
    a = struct('p', p, 'u', u / norm(u), 'len', len, 'aspect', len / max(width, eps));
    if S(1,1) < 1.5 * S(2,2)
        warning("Rod spread is nearly isotropic: axis direction is poorly defined");
    end
end

% Distance of points (rows of P) from the line through p along unit u
function dd = dist_to_line(P, p, u)
    D = P - p;
    dd = vecnorm(D - (D * u') * u, 2, 2);
end

% Rotate points (rows) by angle (rad) about the axis through p along u
function Q = rotate_about(P, p, u, ang)
    T = hinge_transform(struct('p', p, 'u', u), ang);
    Q = (T(1:3,1:3) * (P - p)')' + p;
end

% 4x4 transform: rotation by ang (rad) about the hinge axis
function T = hinge_transform(h, ang)
    T = makehgtform('translate', h.p) * makehgtform('axisrotate', h.u, ang) * ...
        makehgtform('translate', -h.p);
end

function draw_part(parent, part, color)
    patch(parent, 'Faces', part.F, 'Vertices', part.V, 'FaceColor', color, ...
        'EdgeColor', 'none', 'FaceLighting', 'gouraud', 'AmbientStrength', 0.4, ...
        'DiffuseStrength', 0.7, 'SpecularStrength', 0.2);
end

function style_axes(ax)
    axis(ax, 'equal')
    axis(ax, 'vis3d')
    % from above, ahead of the robot and to one side, z up
    view(ax, -37.5, 25)
    ax.CameraUpVector = [0 0 1];
    grid(ax, 'on')
    xlabel(ax, "x, downstream (mm)"); ylabel(ax, "y, span (mm)"); zlabel(ax, "z, up (mm)");
    camlight(ax, 'headlight')
    camlight(ax, 'right')
    material(ax, 'dull')
end

% Axis limits covering the static parts and the wings over the stroke
function lims = stroke_limits(V_static, wings, hinge, dphi_deg)
    lo = min(V_static, [], 1);
    hi = max(V_static, [], 1);
    for w = 1:2
        for a = [min(dphi_deg), max(dphi_deg), 0]
            Vw = rotate_about(wings(w).V, hinge(w).p, hinge(w).u, deg2rad(a));
            lo = min(lo, min(Vw, [], 1));
            hi = max(hi, max(Vw, [], 1));
        end
    end
    pad = 0.05 * max(hi - lo);
    lims = [lo' - pad, hi' + pad];
end
