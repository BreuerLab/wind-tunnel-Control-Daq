function AFAM_Tunnel = load_afam_data

    try
        data = load("R:\ENG_Breuer_Shared\group\AFAM_state.mat");
        AFAM_Tunnel = data.AFAM_Tunnel;   
    catch
        AFAM_Tunnel = load_afam_data;
    end

end