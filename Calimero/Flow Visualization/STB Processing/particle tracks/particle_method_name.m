function m = particle_method_name(p)
% PARTICLE_METHOD_NAME  Method name of the particle-based results, e.g.
% "particle_pool_hr20" (default settings) or "particle_pool_o3_hr20".
    m = "particle";
    if p.mode == "pool", m = "particle_pool"; end
    if strlength(string(p.run_tag)) > 0, m = m + "_" + string(p.run_tag); end
    if p.hr_harmonics > 0, m = m + "_hr" + p.hr_harmonics; end
end
