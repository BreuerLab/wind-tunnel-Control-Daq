function forces = applyBools(forces, sub_drift, modFileName, offsets_files, shift_bool, AoA, nondimensional, norm_factors)
    if (sub_drift)
        [drift] = get_drift(modFileName, offsets_files);
        forces = forces - drift;
    end

    if (shift_bool)
        [center_to_LE, ~, ~, ~, ~] = getWingMeasurements("Flapperoo");
        [mod_plot_data] = shiftPitchMomentToLE(forces, center_to_LE, AoA);
        forces = mod_plot_data;
    end

    if (nondimensional)
        forces = dimensionless(forces, norm_factors);
    end
end