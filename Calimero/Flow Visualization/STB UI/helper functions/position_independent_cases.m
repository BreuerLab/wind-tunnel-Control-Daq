function names = position_independent_cases()
% Cases that don't belong to a downstream position: measurements of the
% freestream alone, e.g. "freestream" (Processed Results\time_avg\
% freestream_time_avg.mat, recorded with the x3 calibration). They are
% part of the new flapper data set, are listed at every downstream
% position in the UIs and use the new flapper trim bounds. Add names here.
names = ["freestream"];
end
