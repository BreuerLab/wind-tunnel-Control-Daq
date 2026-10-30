function out = old_flapper_compat(query, varargin)
% Everything that differs between the old flapper data set (STB Round 1,
% February 2026) and the new flapper data (August/September 2026), in one
% place. The UIs and helpers ask this function instead of hard-coding the
% differences.
%
% Old flapper cases are recognised by their names: they have no new
% flapper position prefix (x1_ ... x5_, MPS_) and aren't turbine cases,
% e.g. "flexible_20deg_2Hz", "UP_one_flexible_10deg_4Hz", "body", "ring".
%
% Queries:
%   tf = old_flapper_compat("is_old", name)
%       true for an old flapper case / type / file name (string array ok)
%
%   b = old_flapper_compat("trim_bounds")
%       trim limits and centre point the old data was analysed with (the
%       values in trim_vel_field.m at commit 5708caa "ILC controller
%       added", 30 July 2026, before the code was changed for the new
%       data). No uncertainty mask existed then.
%
%   b = old_flapper_compat("trim_bounds_for", name, bounds)
%       the old bounds for an old flapper case, otherwise bounds (default
%       default_trim_bounds() if omitted)
%
%   c = old_flapper_compat("phase_offset", type, amp, freq)
%       phase shift (fraction of a wingbeat) applied to an old flapper
%       case's phase-averaged signals. The old flapper had no automated
%       wing homing, so a case can start at a different phase. Add rows to
%       the table below for any other case that needs it.
%
%   t = old_flapper_compat("load_cell_type", type)
%       the wing type used to find the load cell data: position prefixes
%       (x3_, MPS_, UP_one_, UP_two_) stripped, since the load cell is only
%       measured at the robot

switch string(query)
    case "is_old"
        % (turbine cases also have no prefix, but aren't old flapper)
        names = string(varargin{1});
        out = arrayfun(@(n) strlength(get_downstream_prefix(n)) == 0 &&...
            ~contains(n, "turbine", IgnoreCase=true), names);

    case "trim_bounds"
        out.ybounds = [-2.8 2.5];
        out.zbounds = [-2.36 2.55];
        out.y_cen = -2.26;
        out.z_cen = 0.043;
        out.unc_mask = 0;

    case "trim_bounds_for"
        name = string(varargin{1});
        if numel(varargin) > 1 && ~isempty(varargin{2})
            out = varargin{2};
        else
            out = default_trim_bounds();
        end
        if strlength(name) > 0 && old_flapper_compat("is_old", name)
            out = old_flapper_compat("trim_bounds");
        end

    case "phase_offset"
        type = string(varargin{1});
        amp = varargin{2};
        freq = NaN;
        if numel(varargin) > 2
            freq = varargin{3};
        end
        out = 0;
        if ~old_flapper_compat("is_old", type)
            return
        end
        % {type, amplitude (deg), frequency (Hz, NaN = all), shift (cycles)}
        % flexible 10 deg (at the 0.9 m position) started at mid-downstroke
        % rather than the mid-upstroke used for the other cases
        offsets = {
            "flexible", 10, NaN, 0.5
            };
        for k = 1:size(offsets, 1)
            if type == offsets{k, 1} && amp == offsets{k, 2} &&...
                    (isnan(offsets{k, 3}) || freq == offsets{k, 3})
                out = offsets{k, 4};
                return
            end
        end

    case "load_cell_type"
        type = string(varargin{1});
        prefix = get_downstream_prefix(type, true);
        out = type;
        if strlength(prefix) > 0
            out = extractAfter(type, strlength(prefix));
        end

    otherwise
        error("old_flapper_compat:unknownQuery", "Unknown query %s", query)
end
end
