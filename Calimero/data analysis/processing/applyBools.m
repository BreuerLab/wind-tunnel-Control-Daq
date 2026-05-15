function data = applyBools(data, sub_drift, drift, shift_bool, AoA, nondimensional, norm_factors, type_sel, shift_type)
    forces = data(1:6, :);
    if (sub_drift)
        forces = forces - drift(1:6);
    end

    if (shift_bool)
        [center_to_LE, ~, ~, ~, ~, center_to_quartchord] = getWingMeasurements(type_sel);
        
        % choose what type of shift
        if shift_type == "center_to_LE"
            center_to_chord_posn = center_to_LE; % Define the position for shifting
        elseif shift_type == "center_to_quartchord"
            center_to_chord_posn = center_to_quartchord;
        else
            error("Shift dimensions given by shift_type are undefined.")
        end
        
        [mod_plot_data] = shiftPitchMoment(forces, center_to_chord_posn, AoA);
        forces = mod_plot_data;
    end

    if (nondimensional)
        forces = dimensionless(forces, norm_factors);
    end
    data = [forces; data(7:8,:)];
end