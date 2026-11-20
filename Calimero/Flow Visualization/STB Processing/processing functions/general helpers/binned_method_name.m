function m = binned_method_name(bools)
% BINNED_METHOD_NAME  Method name of phase_avg_STB's results: "bin", with
% "_hr" for harmonic regression and "_RPCA" for RPCA filtering.
    m = "bin";
    if isfield(bools, 'harmonic_reg') && bools.harmonic_reg, m = m + "_hr"; end
    if isfield(bools, 'RPCA') && bools.RPCA, m = m + "_RPCA"; end
end
