function v = binned_version_name(bools)
% BINNED_VERSION_NAME  Version part of the binned phase-average file names
% as phase_avg_STB builds them: bools.version, "_hr" added for harmonic
% regression ("hr" alone without a version), "_RPCA" for RPCA. "" = none.
%   e.g. <case>_<v>_phase_avg.mat  ->  v
    v = "";
    if isfield(bools, 'version') && strlength(string(bools.version)) > 0
        v = string(bools.version);
    end
    if isfield(bools, 'harmonic_reg') && bools.harmonic_reg
        if strlength(v) > 0, v = v + "_hr"; else, v = "hr"; end
    end
    if isfield(bools, 'RPCA') && bools.RPCA
        if strlength(v) > 0, v = v + "_RPCA"; else, v = "RPCA"; end
    end
end
