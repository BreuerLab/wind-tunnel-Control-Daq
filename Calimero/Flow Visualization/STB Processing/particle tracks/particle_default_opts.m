function p = particle_default_opts()
% PARTICLE_DEFAULT_OPTS  Settings for the particle-based phase average and
% its integral quantities (particle_process_case), used as bools.particle
% in main_processing / main_processing_batch and by the standalone
% main_particle_processing / main_particle_integrals scripts.
%
% Method name: particle[_pool][_<run_tag>][_hr<hr_harmonics>], e.g.
% particle_pool_hr20 (default settings) or particle_pool_o3_hr20 (run_tag
% "o3"). Files: stb_file_paths(save, case, version, method).

    % ---- what to run ------------------------------------------------------
    p.run  = false;   % run the particle steps after the binned phase average
    p.only = false;   % skip the binned processing (its files must exist)
    p.plot = false;   % quick-look figure after the particle phase average

    % ---- particle data ----------------------------------------------------
    % DaVis particle set(s) of a case: a path, list or wildcard. "" = every
    % particle set in the case folder (the folder above the vc7 folder from
    % get_PIV_paths, e.g. September\x2\x2_wings_20deg_8Hz\*.set);
    % image/vector sets there are skipped. Batch-processed trials (images
    % 1-600, 601-1200, ...) are combined automatically.
    p.set_pattern = "";
    % One-time MAT-file copy of the particles per case (~11 GB for 3000
    % image pairs, built on the first run); "" root = <save folder>\particle_cache.
    % Delete a case's folder after reprocessing its particles in DaVis.
    p.cache      = true;
    p.cache_root = "";

    % ---- particle phase average (particlePhaseAverage) -------------------
    p.mode         = "pool";   % "pool" (particles of a bin fitted together) or "average"
    p.numWorkers   = 8;
    p.binsPerChunk = 16;       % only matters without the cache
    p.run_tag      = "";       % optional tag for non-default fit settings, e.g. "o3"
                               % (keeps them from overwriting the default files)

    % ---- local fit (particleGradientFit) ---------------------------------
    p.fit = struct();
    p.fit.depthAxis    = 1;    % slab normal (analysis frame, x)
    p.fit.depthOrder   = 5;    % 3, 5 or 7 (5 closed most of the x*omega_y gap; 7 was worse)
    p.fit.minParticles = 20;
    p.fit.cutoff       = 2.5;  % neighbourhood radius / sigma
    p.fit.maxResid     = 0.5;  % m/s
    p.fit.mask         = "auto";
    p.fit.robustPasses = 1;
    % Fit at the nodes of the binned grid with sigma = sigma_per_spacing x
    % grid spacing (1.25 x 2.41 mm = 3.0 mm ~ the 48-voxel DaVis bins).
    % false: fit on p.fit.gridSpacing with p.fit.inPlaneSigma.
    p.match_binned_grid = true;
    p.sigma_per_spacing = 1.25;
    p.fit.gridSpacing   = 1.5;  % used only if match_binned_grid = false
    p.fit.inPlaneSigma  = 1.5;

    % ---- integrals (particle_integrals_case) -----------------------------
    p.hr_harmonics = 20;       % harmonic regression across bins, 0 = off
    % binned method whose uncertainty masks the force integrals ("" = the
    % first of "bin", "bin_hr" found); set by process_case to the one just run
    p.binned_method = "";
    % also write the old combined files (until the GUIs read the new layout)
    p.legacy_files = true;
end
