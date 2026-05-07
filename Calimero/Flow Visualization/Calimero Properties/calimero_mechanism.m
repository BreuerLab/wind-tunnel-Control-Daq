function phi = calimero_mechanism(theta, d, r)
    phi = -atan((r*sin(theta)) ./ (d + r*cos(theta)));
end