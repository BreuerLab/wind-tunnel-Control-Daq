% Inputs: results - (n x 7) force transducer data in time
% Returns: norm_data - (n x 7) same data but
%                                non-dimensionalized
function norm_data = non_dimensionalize_data(results, speed)
    rho = 1.204; % kg/m^3 at 20 C 1 atm
    wing_span = 0.266; % m
    wing_chord = 0.088; % m
    total_area = wing_span * wing_chord * 2; % m^2, roughly

    norm_F_factor = (0.5 * rho * total_area * (2*pi*speed * wing_span)^2);
    norm_M_factor = norm_F_factor * wing_chord;

    norm_F = results(:,2:4) / norm_F_factor;
    norm_M = results(:,5:7) / norm_M_factor;
    norm_data = [results(:,1); norm_F; norm_M];
end