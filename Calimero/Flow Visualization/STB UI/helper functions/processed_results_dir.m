function d = processed_results_dir(root)
% PROCESSED_RESULTS_DIR Processed results folder (the one holding phase_avg\
% and time_avg\) of a data root given to the UIs, with a trailing "\".
%
%   d = processed_results_dir(root)
%
%   root - either a data root whose processed results are in a "Processed
%          Results" subfolder, e.g. "W:\STB Round 1\" (old flapper) ->
%          "W:\STB Round 1\Processed Results\", or the processed results
%          folder itself, e.g. "C:\Users\rgissler\Documents\STB Processed
%          Results\" (new flapper), which is returned as is. A folder counts
%          as the processed results folder when it has a phase_avg or
%          time_avg subfolder.

root = string(root);
if ~endsWith(root, ["\", "/"])
    root = root + "\";
end
if isfolder(root + "phase_avg") || isfolder(root + "time_avg")
    d = root;
else
    d = root + "Processed Results\";
end
end
