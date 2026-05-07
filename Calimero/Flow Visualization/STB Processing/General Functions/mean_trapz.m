function B = mean_trapz(A)
    % V1 = fillmissing(A, 'linear', 1);
    % V2 = fillmissing(V1, 'linear', 2);
    V2 = A;
    V2(isnan(V2)) = 0; % median(V2, "all", "omitnan")

    V3 = trapz(V2, 1) / (size(A,1) - 1);
    V4 = trapz(V3, 2) / (size(A,2) - 1);

    B = squeeze(V4);
end