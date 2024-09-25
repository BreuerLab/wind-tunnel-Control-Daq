function cur_ang = Pitch_Angle()
    Deg2Con = 29850.74;
    print_bool = false;
    P1 = Pitch_Read(print_bool);
    cur_ang = (P1.POS+52238083) / (16 * Deg2Con);
    cur_ang = round(cur_ang, 2);
end

