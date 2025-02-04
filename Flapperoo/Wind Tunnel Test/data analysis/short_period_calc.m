% Calculation of short period duration approximating natural frequency of
% object: w_n = (k / m)^(1/2) --> w_n = [ (dM / da) / I]^(1/2)

% https://en.wikipedia.org/wiki/Rock_dove
% https://mathworld.wolfram.com/Spheroid.html

clear

% What if we instead consider bird as prolate spheroid where length of
% spheroid is along birds wingspan and radius of spheroid extends along
% birds body length

m = 0.25; % total mass of prolate spheroid (kg)
r = 0.35/2; % radius of prolate spheroid (meters) --> body length
L = 0.65/2; % half length of prolate spheroid (meters) --> wingspan

I = (2/5)*m*r^2;

k = 2*10^(-3); % dM / da, for half wings was between -0.5 and -4 * 10^(-3)

w_n = (k / I)^(1/2);

T = (2*pi) / w_n;

% What about if the wings were closed? Length of prolate spheroid now in
% line with body length of pigeon

r = 0.12/2; % radius of prolate spheroid (meters) --> body length
L = 0.35/2; % half length of prolate spheroid (meters) --> wingspan

I = (1/5)*m*(r^2 + L^2);

k = 2*10^(-3); % dM / da, for half wings was between -0.5 and -4 * 10^(-3)

w_n = (k / I)^(1/2);

T = (2*pi) / w_n;