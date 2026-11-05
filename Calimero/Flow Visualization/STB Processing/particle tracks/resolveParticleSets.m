function sets = resolveParticleSets(paths)
% RESOLVEPARTICLESETS  Expand paths / wildcards to the DaVis particle sets
% among them (image and vector sets are skipped).
%
%   sets = resolveParticleSets("F:\...\x2_wings_20deg_8Hz\*.set")
%   sets = resolveParticleSets(["F:\...\STB_1-600.set", "F:\...\STB_601-1200.set"])
%
% Returns a string column, in name order within each pattern.

    paths = string(paths(:));
    sets = strings(0, 1);
    for p = paths'
        if contains(p, ["*", "?"])
            d = dir(p);
            d = d(~[d.isdir]);                    % the set's data folder has the same name
            cand = string(fullfile({d.folder}, {d.name}))';
            cand = cand(endsWith(cand, ".set", 'IgnoreCase', true));
        else
            cand = p;
        end
        for c = cand'
            try
                P = loadSTBParticles(c);          % metadata only; errors for non-particle sets
                if P.info.n_blocks > 0, sets(end+1, 1) = c; end %#ok<AGROW>
            catch
                fprintf('  skipping %s (not a particle set)\n', c);
            end
        end
    end
    if isempty(sets)
        error('resolveParticleSets:none', 'No particle sets found for %s.', strjoin(paths, ', '));
    end
end
