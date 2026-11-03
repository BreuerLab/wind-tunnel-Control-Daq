function out = plane_downstream_dists(name)
% Streamwise distances (m) from the robot to the STB imaging planes. The
% one place to set them: phaseAvg_UI, timeAvg_UI and flowField_UI all read
% them from here (convection phase shift). After editing, restart the UIs
% (or run "clear classes") so the class property defaults are re-read.
%
%   d = plane_downstream_dists()        struct with all fields below
%   v = plane_downstream_dists("new")   one field, e.g. "new", "old", "sep"
%
%   x3      robot to the x3 plane (also the old flapper "flexible" plane)
%   sep     new flapper: spacing between neighbouring planes x1 ... x5
%   MPS     robot to the MPS plane
%   old_sep old flapper: spacing between flexible, UP_one and UP_two
%   new     [x1; x2; x3; x4; x5; MPS]
%   old     [flexible; UP_one; UP_two]

d.x3 = 0.9;
d.sep = 0.378;
d.MPS = 1.0;
d.old_sep = 0.37;

d.new = [d.x3 + (-2:2)' * d.sep; d.MPS];
d.old = d.x3 + (0:2)' * d.old_sep;

if nargin == 0
    out = d;
else
    out = d.(char(name));
end
end
