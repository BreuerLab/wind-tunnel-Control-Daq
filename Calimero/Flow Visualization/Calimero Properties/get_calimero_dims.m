function [d, r] = get_calimero_dims(amp)
    d = 20;
    if amp == 10
        r = 3.47;
    elseif amp == 20
        r = 6.84;
    elseif amp == 30
        r = 10;
    end
end