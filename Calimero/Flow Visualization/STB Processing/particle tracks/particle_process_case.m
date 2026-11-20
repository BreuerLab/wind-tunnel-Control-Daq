function method = particle_process_case(PIV_case_name, save_filepath_local, version, p)
% PARTICLE_PROCESS_CASE  Particle-based phase average and its integral
% quantities for one case (particle_phase_avg_case, then
% particle_integrals_case). Called by process_case when bools.particle.run
% is true; the binned phase average of the case must exist (it supplies the
% phase binning, grid, uncertainty mask and DAQ data).
%
%   method = particle_process_case(PIV_case_name, save_filepath_local, version, p)
%   version : binning variant (bools.version, "" = default)

    if nargin < 4 || isempty(p), p = particle_default_opts(); end
    fprintf('\n----- Particle processing: %s (method %s) -----\n', ...
            PIV_case_name, particle_method_name(p));
    t0 = tic;
    p_fit = p;  p_fit.hr_harmonics = 0;
    Pfit = stb_file_paths(save_filepath_local, PIV_case_name, version, particle_method_name(p_fit));
    if isfield(p, 'reuse_fit') && p.reuse_fit && isfile(Pfit.fit)
        fprintf('Reusing the saved particle fit %s\n', Pfit.fit);
    else
        particle_phase_avg_case(PIV_case_name, save_filepath_local, version, p);
    end
    method = particle_integrals_case(PIV_case_name, save_filepath_local, version, p);
    fprintf('Particle processing of %s took %.1f min\n', PIV_case_name, toc(t0)/60);
end
