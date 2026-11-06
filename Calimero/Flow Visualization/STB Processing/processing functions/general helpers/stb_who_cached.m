function vars = stb_who_cached(file)
% STB_WHO_CACHED  who('-file', file), remembered until the file changes.
% The GUIs ask for the variable list of the same files many times per plot.
    persistent cache
    if isempty(cache), cache = containers.Map('KeyType', 'char', 'ValueType', 'any'); end
    file = char(file);
    info = dir(file);
    stamp = [info.datenum, info.bytes];
    if isKey(cache, file)
        c = cache(file);
        if isequal(c.stamp, stamp)
            vars = c.vars;
            return
        end
    end
    vars = who('-file', file);
    cache(file) = struct('stamp', stamp, 'vars', {vars});
end
