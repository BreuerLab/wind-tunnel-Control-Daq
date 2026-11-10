function A = stbBlockAttributes(setPath, blocks)
% STBBLOCKATTRIBUTES  DaVis attributes of particle-set blocks (image pairs),
% e.g. to find which recording images / vc7 files a particle set covers.
%
%   A = stbBlockAttributes(setPath)          % global attributes of the set
%   A = stbBlockAttributes(setPath, blocks)  % 1-based blocks -> struct array
%
% Each element of A has fields .block and .attr (a struct of strings; names
% made MATLAB-valid). Attributes such as AcqTimeSeries, LoadSet,
% LoadSetIndex or TomoVolumeSubSetName are usually copied from the image
% set the particles were computed from.

    mod = stbPyModule(["block_attributes", "global_attributes"]);
    setPath = strrep(char(setPath), '\', '/');

    if nargin < 2 || isempty(blocks)
        A = toStruct(mod.global_attributes(setPath));
        return
    end
    A = struct('block', num2cell(blocks(:)'), 'attr', []);
    for k = 1:numel(blocks)
        A(k).attr = toStruct(mod.block_attributes(setPath, int64(blocks(k) - 1)));
    end
end

function s = toStruct(d)
    s = struct();
    keys = cell(py.list(d.keys()));
    for i = 1:numel(keys)
        k = char(keys{i});
        s.(matlab.lang.makeValidName(k)) = char(d.get(keys{i}));
    end
end
