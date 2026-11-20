function d = force_measurements_dir(root)
% FORCE_MEASUREMENTS_DIR Load cell data folder ("Force Measurements\") that
% goes with a data root given to the UIs, with a trailing "\".
%
%   d = force_measurements_dir(root)
%
%   Looks, in order, for:
%     <root>\Force Measurements\          e.g. W:\STB Round 1\ (old flapper)
%     <parent of root>\Force Measurements\ when root is a processed results
%                                         folder, e.g. C:\Users\rgissler\
%                                         Documents\STB Processed Results\
%     F:\Force Measurements\              where the new flapper load cell
%                                         data was kept with the old F:\ root
%   and returns the first that exists (the first candidate if none does,
%   so the "not found" messages name the expected folder).

root = string(root);
if ~endsWith(root, ["\", "/"])
    root = root + "\";
end
parent = string(fileparts(char(extractBefore(root, strlength(root)))));
candidates = [root + "Force Measurements\", parent + "\Force Measurements\", "F:\Force Measurements\"];
d = candidates(1);
for k = 1:numel(candidates)
    if isfolder(candidates(k))
        d = candidates(k);
        return
    end
end
end
