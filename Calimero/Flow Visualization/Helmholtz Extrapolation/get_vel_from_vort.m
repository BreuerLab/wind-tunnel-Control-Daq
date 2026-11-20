function [velX, velY, velZ] = get_vel_from_vort(dx, dy, dz, vortX, vortY, vortZ)
% Velocity induced by a vorticity field (Biot-Savart), solved in Fourier
% space on a box that is periodic in all three directions:
%
%   lap(psi) = -omega,  u = curl(psi)   =>   u_hat = i k x omega_hat / |k|^2
%
% vortX, vortY, vortZ : [Nx Ny Nz] on a uniform grid with spacings dx, dy,
%                       dz (all in the same length unit, e.g. chords). The
%                       box lengths are N*d, so the field repeats with
%                       period Nx*dx in x (one wingbeat for the frozen-flow
%                       axis) and Ny*dy, Nz*dz in y and z.
% velX, velY, velZ    : [Nx Ny Nz] induced velocity, in the units of
%                       vorticity * length (U for omega L/U and lengths in
%                       chords). The uniform (k = 0) part, e.g. the
%                       freestream, can't be recovered and is zero.
%
% Only the solenoidal part of omega contributes (the k-parallel part drops
% out of k x omega_hat), so noise in div(omega) doesn't leak in.

[Nx, Ny, Nz] = size(vortX);

[kx, kx_d] = wavenumbers(Nx, dx);
[ky, ky_d] = wavenumbers(Ny, dy);
[kz, kz_d] = wavenumbers(Nz, dz);
ky = reshape(ky, 1, []); ky_d = reshape(ky_d, 1, []);
kz = reshape(kz, 1, 1, []); kz_d = reshape(kz_d, 1, 1, []);

K2 = kx.^2 + ky.^2 + kz.^2;
K2(1,1,1) = 1; % k = 0: numerator is zero there, so the mean velocity is 0

wx = fftn(vortX);
wy = fftn(vortY);
wz = fftn(vortZ);

velX = real(ifftn(1i * (ky_d .* wz - kz_d .* wy) ./ K2));
velY = real(ifftn(1i * (kz_d .* wx - kx_d .* wz) ./ K2));
velZ = real(ifftn(1i * (kx_d .* wy - ky_d .* wx) ./ K2));
end

% FFT wavenumbers (column vector) for N points spaced d apart, and the
% same with the Nyquist mode zeroed for first derivatives (an odd
% derivative of that mode isn't real-valued)
function [k, k_d] = wavenumbers(N, d)
k = (2*pi / (N*d)) * [0:ceil(N/2)-1, -floor(N/2):-1]';
k_d = k;
if mod(N, 2) == 0
    k_d(N/2 + 1) = 0;
end
end
