function added_mass = get_added_mass(pos, speed, acc)
    rho = 1.225; % kg/m^3
    h = 0.001; % 1 mm thick wing

    R = 0.3; % temp value for axis of rotation to wing tip
    r = 0:0.01:R;
    c = 0.07; % temp value for chord
    int = trapz(r, c*r);
    added_mass = rho * h * (acc .* cos(pos) + speed.^2 .* sin(pos)) * int;
end