function normalized_data = dimensionless(force_data, norm_factors)
    normalized_data = zeros(size(squeeze(force_data)));
    for i = 1:6
        if (i <= 3)
            normalized_data(i,:) = force_data(i,:) / norm_factors(1);
        else
            normalized_data(i,:) = force_data(i,:) / norm_factors(2);
        end
    end
end