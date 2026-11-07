function P = stb_file_paths(save_root, PIV_case_name, version, method)
% STB_FILE_PATHS  Processed-file paths of a phase-averaged case.
%
%   P = stb_file_paths(save_root, PIV_case_name, version, method)
%
%   version : binning variant (bools.version, e.g. "coarse"; "" = default).
%             It names the shared file, because the phase binning (and so
%             everything in it) can differ between variants.
%   method  : how the flow fields were computed: "bin", "bin_hr",
%             "bin_RPCA" (DaVis binning, phase_avg_STB) or
%             "particle_pool_hr20" etc. (particle tracks); "" = only the
%             shared file is wanted
%
%   P.dir      <save_root>\phase_avg
%   P.shared   <case>[_<version>]_shared.mat           DAQ, binning, grid, frames
%   P.fields   <case>[_<version>]_<method>_fields.mat     phase-averaged flow fields
%              (not *_phase_avg.mat, so they can't collide with the legacy
%              combined files and the legacy GUIs don't list them)
%   P.integral <case>[_<version>]_<method>_integral.mat   integral quantities
%   P.fit      <save_root>\particle_fits\<case>[_<version>]_<method>_fit.mat
%              (particle methods: the fit on its own grid, before resampling)
%   P.stem     <case>[_<version>],  P.method

    if nargin < 4, method = ""; end
    stem = string(PIV_case_name);
    if strlength(string(version)) > 0, stem = stem + "_" + string(version); end
    P.dir = fullfile(string(save_root), "phase_avg");
    P.stem = stem;
    P.method = string(method);
    P.shared = fullfile(P.dir, stem + "_shared.mat");
    if strlength(P.method) > 0
        P.fields   = fullfile(P.dir, stem + "_" + P.method + "_fields.mat");
        P.integral = fullfile(P.dir, stem + "_" + P.method + "_integral.mat");
        P.fit      = fullfile(string(save_root), "particle_fits", stem + "_" + P.method + "_fit.mat");
    else
        P.fields = "";  P.integral = "";  P.fit = "";
    end
end
