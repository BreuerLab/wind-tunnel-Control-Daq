function M = merge_stb_structs(varargin)
% MERGE_STB_STRUCTS  Combine shared, flow-field and integral structs of a
% case into one struct (later arguments take precedence), e.g. for the
% secondary values or the legacy single-file layout.
%   M = merge_stb_structs(Sh, Sf)  or  merge_stb_structs(Sh, Sf, Si)
    M = struct();
    for a = 1:nargin
        S = varargin{a};
        if isempty(S), continue; end
        f = fieldnames(S);
        for i = 1:numel(f), M.(f{i}) = S.(f{i}); end
    end
end
