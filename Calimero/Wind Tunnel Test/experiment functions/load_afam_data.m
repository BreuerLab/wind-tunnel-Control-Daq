function AFAM_Tunnel = load_afam_data

    try
        load("R:\ENG_Breuer_Shared\group\AFAM_state.mat");
    catch
        AFAM_Tunnel = load_afam_data;
    end

end