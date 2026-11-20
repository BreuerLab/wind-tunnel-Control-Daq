function terms = transport_term_list()
% Stretching/tilting terms of the inviscid vorticity transport equation,
%   D(omega_i)/Dt = omega_x du_i/dx + omega_y du_i/dy + omega_z du_i/dz,
% as {saved name, vorticity field, gradient field}. The term along the
% component's own direction is stretching, the other two are tilting.
% Used by calc_secondary_vals_common (planar integrals, saved in the
% _integral file) and the STB UIs.
terms = {
    % omega_x equation (u_i = u)
    "wx_stretch", "vortX", "dudx"
    "wx_tilt_y",  "vortY", "dudy"
    "wx_tilt_z",  "vortZ", "dudz"
    % omega_y equation (u_i = v)
    "wy_tilt_x",  "vortX", "dvdx"
    "wy_stretch", "vortY", "dvdy"
    "wy_tilt_z",  "vortZ", "dvdz"
    % omega_z equation (u_i = w)
    "wz_tilt_x",  "vortX", "dwdx"
    "wz_tilt_y",  "vortY", "dwdy"
    "wz_stretch", "vortZ", "dwdz"
    };
end
