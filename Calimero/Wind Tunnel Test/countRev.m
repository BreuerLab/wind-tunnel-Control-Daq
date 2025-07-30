function [distFromZero_new] = countRev(theta, distFromZero)
    % Check input
    if isempty(theta)
        error('Input array theta must not be empty.');
    end

     % Initialize output
    startPos = theta(1);
    endPos = theta(end);

      % Set tolerance for detecting a "return" to starting angle
    tol = 0.1;  % adjust as needed based on noise


    % Initialize count
    hitCount = 0;

    % Loop through theta and count returns to startPos
    for i = 2:length(theta)
        % Check if we're near the starting position (and just passed through)
        if abs(theta(i) - startPos) < tol && abs(theta(i-1) - startPos) >= tol
            hitCount = hitCount + 1;
        end
    end

    if (endPos - startPos < 0)
        first = 5 - startPos;
        second = endPos;

        hitCount = hitCount + (first + second)/5;
    else
        hitCount = hitCount + (endPos-startPos)/5;
    end


    % Every 9 returns is one full revolution
    numRev = hitCount / 9;
    decimalRev = mod(numRev, 1);

    distFromZero_temp = distFromZero + decimalRev;
    distFromZero_new = mod(distFromZero_temp, 1);
end