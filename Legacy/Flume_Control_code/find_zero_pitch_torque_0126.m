function find_zero_pitch_torque_0126
% Finds the minimum lift on wallace hydrofoil while under flow.
global pitch_bias
disp('finding zero.  Wallace will now move +/- 5 degrees')
move_new_pos_3rigs([0 0 0 0 5 0],2);
[out,prof] = move_new_pos_3rigs([0 0 0 0 -5 0],10);



Lift(:,1) = (out(:,7).*cos(out(:,5))-out(:,8).*sin(out(:,5)));
Torque(:,1) = out(:,12);

f=polyfit(smooth(Lift,100)',1:numel(Lift),1);
f_tq = polyfit(smooth(Torque,100)',1:numel(Torque),1);

plot(1:numel(prof(:,1)),prof(:,5),1:numel(out(:,8)),smooth(Lift,100),1:numel(Lift),((1:numel(Lift))-f(2))./f(1))
% 1:numel(lift) = Lift*a + b
%Lift = (1:numel(Lift)-b)./a)
[out,prof2] = move_new_pos_3rigs([0 0 0 0 5 0],10);



Lift(:,1) = (out(:,7).*cos(out(:,5))-out(:,8).*sin(out(:,5)));
Torque(:,1) = out(:,12);

f1=polyfit(smooth(Lift,100)',1:numel(Lift),1);
f_tq1 = polyfit(smooth(Torque,100)',1:numel(Torque),1);

hold on
plot(1:numel(prof2(:,1)),prof2(:,5),1:numel(out(:,8)),smooth(Lift,100),1:numel(Lift),((1:numel(Lift))-f1(2))./f1(1))
hold off




if round(f(2)) < 0 || round(f(2)) > numel(prof(:,5))
    disp('Pitch out of range. Expanding search.')
    move_new_pos_3rigs([0 0 0 0 15 0],2);
    [out,prof] = move_new_pos_3rigs([0 0 0 0 -15 0],10);



    Lift(:,1) = (out(:,7).*cos(out(:,5))-out(:,8).*sin(out(:,5)));

    f=polyfit(smooth(Lift,100)',1:numel(Lift),1);
    plot(1:numel(prof(:,1)),prof(:,5),1:numel(out(:,8)),smooth(Lift,100),1:numel(Lift),((1:numel(Lift))-f(2))./f(1))
    hold on
        [out,prof2] = move_new_pos_3rigs([0 0 0 0 15 0],10);



    Lift(:,1) = (out(:,7).*cos(out(:,5))-out(:,8).*sin(out(:,5)));

    f1=polyfit(smooth(Lift,100)',1:numel(Lift),1);
    plot(1:numel(prof2(:,1)),prof2(:,5),1:numel(out(:,8)),smooth(Lift,100),1:numel(Lift),((1:numel(Lift))-f1(2))./f1(1))
    hold off
    
    
    
    pitch_bias(3) = mean([prof(round(f(2)),5) prof2(round(f1(2)),5)]);
    
    
    if round(f(2)) < 0 || round(f(2)) > numel(prof(:,5))
        error('Pitch out of range.  Manually align pitch.')
    end
    
    move_new_pos_3rigs([0 0 0 0 5 0],2);
    [out,prof] = move_new_pos_3rigs([0 0 0 0 -5 0],10);



    Lift(:,1) = (out(:,7).*cos(out(:,5))-out(:,8).*sin(out(:,5)));

    f=polyfit(smooth(Lift,100)',1:numel(Lift),1);
    plot(1:numel(prof(:,1)),prof(:,5),1:numel(out(:,8)),smooth(Lift,100),1:numel(Lift),((1:numel(Lift))-f(2))./f(1))
    % 1:numel(lift) = Lift*a + b
    %Lift = (1:numel(Lift)-b)./a)
    [out,prof2] = move_new_pos_3rigs([0 0 0 0 5 0],10);



    Lift(:,1) = (out(:,7).*cos(out(:,5))-out(:,8).*sin(out(:,5)));

    f1=polyfit(smooth(Lift,100)',1:numel(Lift),1);
    hold on
    plot(1:numel(prof2(:,1)),prof2(:,5),1:numel(out(:,8)),smooth(Lift,100),1:numel(Lift),((1:numel(Lift))-f1(2))./f1(1))
    hold off
    
    
end



% pitch_bias(3) = mean([prof(round(f(2)),5) prof2(round(f1(2)),5)]) ;
pitch_bias(3) = mean([prof(round(f_tq(2)),5) prof2(round(f_tq1(2)),5)])

disp(['Pitch Bias (volts):  ',num2str(pitch_bias)])

move_to_zero;

% disp(['Pitch Bias (deg)',num2str(conv_last_out(last_out))])

end
