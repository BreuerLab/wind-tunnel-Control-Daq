function v = particle_version_name(version, p)
% PARTICLE_VERSION_NAME  Version name of the particle results in the
% legacy single-file layout: [<version>_]<particle_method_name(p)>.
    v = particle_method_name(p);
    if strlength(string(version)) > 0, v = string(version) + "_" + v; end
end
