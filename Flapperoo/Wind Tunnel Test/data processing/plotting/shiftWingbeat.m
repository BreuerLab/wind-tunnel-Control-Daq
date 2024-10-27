function [shifted_data] = shiftWingbeat(data)
    % I used to run the experiments such that the wings always
    % started at the highest position (top of upstroke), but that
    % messed up the taring process. So what I do now is start the
    % wings at midstroke with the green crank pointed upstream,
    % roughly parallel to the flat top of the gearbox. It's not
    % perfectly in the same spot from day to day, but at least
    % for a single trial I know it starts and ends at the exact
    % same spot. Since the data now starts at midstroke with the
    % wings proceeding upwards, I need to shift the cycle by a
    % 1/4 such that the data starts on downstroke for a better
    % plot.
    shifted_data = [data(:, 1 + round(length(data)*(1/4)):end) data(:, 1:round(length(data)*(1/4)))];
end

