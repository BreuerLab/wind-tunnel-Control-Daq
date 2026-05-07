function [velX, velY, velZ] = get_vel_from_vort(x_arr, y_arr ,z_arr, vortX, vortY, vortZ)    
    % L(1) = range(x_arr);
    % L(2) = range(y_arr);
    char_L = 0.07;
    L(1) = 1.2 / char_L; % meters, width of tunnel
    L(2) = 1.2 / char_L; % meters, height of tunnel
    L(3) = range(z_arr);

    % negative sign used since calc identity produces it
    [psiX] = getStreamFunction(-vortX, L);
    [psiY] = getStreamFunction(-vortY, L);
    [psiZ] = getStreamFunction(-vortZ, L);

    [x, y, z] = ndgrid(x_arr, y_arr, z_arr);
    [velX, velY, velZ] = calculateVorticity(x,y,z,psiX,psiY,psiZ);
end