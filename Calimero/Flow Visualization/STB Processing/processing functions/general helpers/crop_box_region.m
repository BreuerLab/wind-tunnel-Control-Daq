function mask = crop_box_region(y, z, bounds)
% CROP_BOX_REGION Points of the trimmed wake plane inside the Crop Box,
% left out of the force integrals together with the uncertainty mask
% (apply_unc_mask, extra_mask).
%
%   mask = crop_box_region(y, z, bounds)
%
%   y, z   - trimmed grid from trim_vel_field (y/L, z/L, both shifted so
%            bounds.y_cen, bounds.z_cen are the origin), [ny nz]
%   bounds - trim bounds; bounds.crop_box = [ymin ymax zmin zmax] (y/L, z/L)
%            with y from the mirror centreline (y_cen) and z unshifted
%            (as plotted in flowField_UI, same as bounds.zbounds).
%            Missing or [] = no crop box.
%
%   mask is [ny nz] logical, true = left out; [] if there is no box or it
%   holds no points. Used by the live forces (get_PIV_force, timeAvg_UI's
%   Crop Box); flowField_UI's Crop Box uses the same convention.

mask = [];
if ~isfield(bounds, 'crop_box') || numel(bounds.crop_box) ~= 4
    return
end
b = bounds.crop_box;
z_cen = 0;
if isfield(bounds, 'z_cen'), z_cen = bounds.z_cen; end
z_abs = z + z_cen;
m = y > b(1) & y < b(2) & z_abs > b(3) & z_abs < b(4);
if any(m(:))
    mask = m;
end
end
