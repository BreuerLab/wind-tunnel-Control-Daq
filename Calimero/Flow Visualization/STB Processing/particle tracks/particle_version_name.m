function v = particle_version_name(binned_version, p)
% PARTICLE_VERSION_NAME  Version name of the particle-based files, e.g.
% "particle_pool_o5s30_hr20" (prefixed with the binned version if any).
    v = "particle";
    if p.mode == "pool", v = "particle_pool"; end
    if strlength(string(p.run_tag)) > 0, v = v + "_" + string(p.run_tag); end
    if p.hr_harmonics > 0, v = v + "_hr" + p.hr_harmonics; end
    if strlength(string(binned_version)) > 0, v = string(binned_version) + "_" + v; end
end
