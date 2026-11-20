function out = plane_downstream_dists(name)
% Streamwise distances (m) from the robot to the STB imaging planes and the
% wake convection speed used for the convection phase shift. The one place
% to set them: phaseAvg_UI, timeAvg_UI and flowField_UI all read them from
% here. After editing, restart the UIs (or run "clear classes") so the
% class property defaults are re-read.
%
%   d = plane_downstream_dists()        struct with all fields below
%   v = plane_downstream_dists("new")   one field, e.g. "new", "sep"
%
%   x3         robot to the x3 plane (also the old flapper "flexible" plane)
%   sep        spacing between neighbouring planes (x1 ... x5, and the old
%              flapper flexible, UP_one, UP_two)
%   MPS        robot to the MPS plane
%   conv_speed convection speed of the wake (m/s)
%   new        [x1; x2; x3; x4; x5; MPS]
%   old        [flexible; UP_one; UP_two]

% At x2, leading edge of wing is 61 cm from back of calibration target and
% trailing edge near root of wing is 54 cm from back of cal target
% At x3, I don't seem to have a good photo, but from another photo LE is
% probably 96 cm from back of calibration target

d.x3 = 0.96;
d.sep = 0.378;
d.MPS = 1.0;
d.conv_speed = 4;

d.new = [d.x3 + (-2:2)' * d.sep; d.MPS];
d.old = d.x3 + (0:2)' * d.sep;

if nargin == 0
    out = d;
else
    out = d.(char(name));
end
end
