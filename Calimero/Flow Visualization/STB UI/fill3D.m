% Helper function to handle the 3-way fill
function A_filled = fill3D(A)
    if ~any(isnan(A), 'all')
        A_filled = A;
        return;
    end
    % Interpolate in all 3 directions
    V1 = fillmissing(A, 'linear', 1);
    V2 = fillmissing(A, 'linear', 2);
    V3 = fillmissing(A, 'linear', 3);
    
    % Average them, omitting NaNs to handle edges/extrapolation gracefully
    A_filled = mean(cat(4, V1, V2, V3), 4, 'omitnan');
    
    % Final check: If large holes remain that linear couldn't reach, 
    % use nearest neighbor as a fallback
    if any(isnan(A_filled), 'all')
        A_filled = fillmissing(A_filled, 'nearest', 1);
    end
end