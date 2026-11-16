function model = load_robot_model(cfg)
% LOAD_ROBOT_MODEL Calimero's CAD parts (STL) in the wind tunnel frame,
% with the shoulder axis of each wing, for drawing the robot with the wake
% (flowField_UI) or on its own (robot_flap_test).
%
%   model = load_robot_model(cfg)
%
%   cfg.dir           folder of the STLs
%   cfg.body_file     body (everything that doesn't flap)
%   cfg.wing_files    [left, right] wings
%   cfg.rod_files     [rod1, rod2] shoulder rods (each wing hinges on the
%                     rod whose axis passes closest to it)
%   cfg.cad_to_tunnel 3x3 rotation, rows = tunnel x (downstream), y (span),
%                     z (up) in CAD coordinates
%   cfg.up_dir        "up" in the tunnel frame (default [0 0 1]): positive
%                     wing angle raises the wingtip along it
%   cfg.max_faces     per part; larger meshes are reduced (default 1e5)
%
%   model.parts      struct array (F, V, moves): body, rods, then wings;
%                    moves = 0 for the static parts, 1 / 2 for each wing
%   model.hinge(w)   p (point on the axis), u (unit direction, signed so
%                    positive rotation raises wing w's tip), tip (wingtip)
%   model.units      "mm" (the STLs' units, unchanged)
%
% The STLs must share one coordinate system (exported from the assembly
% without "translate to positive space"). See robot_posed_mesh for the
% mesh at a wing angle.

if ~isfield(cfg, 'up_dir') || isempty(cfg.up_dir)
    cfg.up_dir = [0 0 1];
end
if ~isfield(cfg, 'max_faces') || isempty(cfg.max_faces)
    cfg.max_faces = 1e5;
end
R = cfg.cad_to_tunnel;
assert(abs(det(R) - 1) < 1e-9, "cad_to_tunnel must be a rotation (det = +1)")
up = cfg.up_dir(:)' / norm(cfg.up_dir);

body = load_part(fullfile(cfg.dir, cfg.body_file), cfg.max_faces, R);
for k = 1:2
    wings(k) = load_part(fullfile(cfg.dir, cfg.wing_files(k)), cfg.max_faces, R); %#ok<AGROW>
    rods(k)  = load_part(fullfile(cfg.dir, cfg.rod_files(k)), cfg.max_faces, R); %#ok<AGROW>
end

% shoulder axes: principal direction of each rod through its centroid
for k = 1:2
    V = rods(k).V;
    p = mean(V, 1);
    [~, ~, W] = svd(V - p, 'econ');
    ax_fit(k) = struct('p', p, 'u', W(:,1)' / norm(W(:,1))); %#ok<AGROW>
end

% rod -> wing: the rod whose axis passes closest to the wing
dist = zeros(2, 2);
for w = 1:2
    for k = 1:2
        dist(w, k) = min(dist_to_line(wings(w).V, ax_fit(k).p, ax_fit(k).u));
    end
end
if dist(1,1) + dist(2,2) <= dist(1,2) + dist(2,1)
    rod_of_wing = [1 2];
else
    rod_of_wing = [2 1];
end

% sign of each axis so positive rotation raises the tip (farthest vertex)
for w = 1:2
    a = ax_fit(rod_of_wing(w));
    [~, i_tip] = max(dist_to_line(wings(w).V, a.p, a.u));
    tip = wings(w).V(i_tip, :);
    u = a.u;
    tip_moved = rotate_about(tip, a.p, u, deg2rad(1));
    if dot(tip_moved - tip, up) < 0
        u = -u;
    end
    hinge(w) = struct('p', a.p, 'u', u, 'tip', tip); %#ok<AGROW>
end

parts = struct('F', {body.F, rods(1).F, rods(2).F, wings(1).F, wings(2).F}, ...
    'V', {body.V, rods(1).V, rods(2).V, wings(1).V, wings(2).V}, ...
    'moves', {0, 0, 0, 1, 2});
model = struct('parts', parts, 'hinge', hinge, 'units', "mm");
end

function part = load_part(file, max_faces, R)
    if ~isfile(file)
        error("load_robot_model:missing", "Not found: %s", file);
    end
    TR = stlread(file);
    F = TR.ConnectivityList;
    V = TR.Points;
    if size(F, 1) > max_faces
        [F, V] = reducepatch(F, V, max_faces);
    end
    part = struct('F', F, 'V', V * R.');
end

function dd = dist_to_line(P, p, u)
    D = P - p;
    dd = vecnorm(D - (D * u') * u, 2, 2);
end

function Q = rotate_about(P, p, u, ang)
    T = makehgtform('axisrotate', u, ang);
    Q = (T(1:3,1:3) * (P - p)')' + p;
end
