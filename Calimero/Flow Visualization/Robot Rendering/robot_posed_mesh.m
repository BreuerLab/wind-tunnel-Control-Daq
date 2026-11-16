function [F, V] = robot_posed_mesh(model, dphi_deg)
% ROBOT_POSED_MESH The robot (load_robot_model) as one mesh with both
% wings rotated dphi_deg about their shoulder axes from the exported pose
% (positive raises the wingtips). Tunnel frame, STL units (mm).
%
%   [F, V] = robot_posed_mesh(model, dphi_deg)

F = zeros(0, 3);
V = zeros(0, 3);
ang = deg2rad(dphi_deg);
for k = 1:numel(model.parts)
    P = model.parts(k);
    Vk = P.V;
    if P.moves > 0 && ang ~= 0
        h = model.hinge(P.moves);
        T = makehgtform('axisrotate', h.u, ang);
        Vk = (T(1:3,1:3) * (Vk - h.p)')' + h.p;
    end
    F = [F; P.F + size(V, 1)]; %#ok<AGROW>
    V = [V; Vk]; %#ok<AGROW>
end
end
