function data = applyBools(data, sub_drift, drift, shift_bool, AoA, nondimensional, norm_factors)
    forces = data(1:6, :);
    if (sub_drift)
        forces = forces - drift(1:6);
    end

    if (shift_bool)
        [center_to_LE, ~, ~, ~, ~] = getWingMeasurements("Flapperoo");
        [mod_plot_data] = shiftPitchMomentToLE(forces, center_to_LE, AoA);
        forces = mod_plot_data;
    end

    if (nondimensional)
        forces = dimensionless(forces, norm_factors);
    end
    data = [forces; data(7:8,:)];
end