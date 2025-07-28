function galil = galil_setup(addr)    
    % Connect to the Galil device.
    galil = actxserver("galil");
    % Set the Galil's address.
    galil.address = addr;
end