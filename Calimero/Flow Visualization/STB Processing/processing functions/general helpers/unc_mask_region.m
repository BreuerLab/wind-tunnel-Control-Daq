function mask = unc_mask_region(unc, thresh, mode)
% UNC_MASK_REGION Points left out of the wake force integrals because of
% high measurement uncertainty.
%
%   mask = unc_mask_region(unc, thresh, mode)
%
%   unc    - total uncertainty (uncTot / U) on the trimmed grid, [ny nz] or
%            [ny nz nb]; averaged over dim 3 (the time averaged uncertainty)
%   thresh - threshold as a fraction of the freestream speed (e.g. 0.02);
%            [] or <= 0 returns mask = []
%   mode   - "threshold" (default): mask every point whose uncertainty is
%            above thresh or NaN (never measured).
%            "outer": mask only what lies outside the largest region
%            enclosed by the thresh contour. The largest connected region
%            (4-connected) with uncertainty <= thresh is kept together with
%            any holes inside it, so high-uncertainty spots surrounded by
%            good data (vortex cores, where seeding is poor) stay in the
%            integrals while the poorly resolved FoV edges are removed.
%            This is the grid version of "mask outside the largest polygon
%            of the thresh contour"; working on the grid avoids the open
%            contour segments contourc returns where a contour runs into
%            the window edge.
%
%   mask is [ny nz] logical, true = left out.

mask = [];
if nargin < 2 || isempty(thresh) || thresh <= 0
    return
end
if nargin < 3 || isempty(mode)
    mode = "threshold";
end

unc_t = mean(unc, 3, "omitnan");
bad = unc_t > thresh | isnan(unc_t);

switch lower(string(mode))
    case "threshold"
        mask = bad;

    case "outer"
        CC = bwconncomp(~bad, 4);
        if CC.NumObjects == 0
            warning("unc_mask_region:noRegion", ...
                "No point has uncertainty below %.3g U; the whole plane is masked.", thresh)
            mask = true(size(unc_t));
            return
        end
        [~, k] = max(cellfun(@numel, CC.PixelIdxList));
        keep = false(size(unc_t));
        keep(CC.PixelIdxList{k}) = true;
        % holes = regions not connected to the window edge
        keep = imfill(keep, 4, 'holes');
        mask = ~keep;

    otherwise
        error("unc_mask_region: unknown mode ""%s"" (use ""threshold"" or ""outer"")", mode)
end
end
