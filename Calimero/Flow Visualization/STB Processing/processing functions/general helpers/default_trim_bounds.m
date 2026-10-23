function bounds = default_trim_bounds()
% Region of the wake kept for integral quantities (trim_vel_field), all
% nondimensional (divided by L). The data is shifted so (y_cen, z_cen)
% becomes the origin.
%
% Single source for the default values, used by process_case (stored
% forces) and the STB UIs (Live Calculate). timeAvg_UI starts from these
% and lets you adjust them in the sidebar.

% ybounds = [-2.7 2]; % roughly -0.15 to 0.15 meters
% zbounds = [-2.36 2.55]; % roughly -0.2 to 0.2 meters
% ybounds = [-2.8 2.5]; % roughly -0.15 to 0.15 meters
% % zbounds = [-2.36 2.55]; % roughly -0.2 to 0.2 meters
% 
% y_cen = -2.26;
% z_cen = 0.043;

bounds.ybounds = [-2.4 2.8];
bounds.zbounds = [-2.9 3.1];
bounds.y_cen = -2.06;
bounds.z_cen = -0.35;
end
