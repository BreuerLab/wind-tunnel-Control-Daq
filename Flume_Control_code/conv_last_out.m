function out = conv_last_out(profs)

global pitch_bias



       p00 =      0.9543*1.975/2;%  (0.9437, 0.965)
out(:,2)=profs(:,2).*0.03.*p00;
p00 =      0.9793; % (0.9755, 0.9831)
out(:,6)=-profs(:,6).*0.03.*p00;
 p00 =       0.996; %  (0.9921, 0.9999)
out(:,4)=profs(:,4).*0.03.*p00;
% Pitch 1 and 2

out(:,1)=-(profs(:,1)-pitch_bias(1))./5.*(360)/2/45*56/5;
% out(:,3)=-profs(:,3).*5./(360)*2*60/74 + pitch_offset2;%/1.0126
out(:,5)=(profs(:,5)-pitch_bias(3))/5./10*30000/12800*360/1.00;%5:1 gear *( 10 volts /30000 steps)  * (12800 steps/ revolution) * calibration gain 4/4/2016
%Servo motor
% out(:,3)=-profs(:,3)*1.*10/2000*1000/360*1.00*90/57.42+pitch_offset2;
out(:,3)=-(profs(:,3)-pitch_bias(2))./5.*(360)/2/65*81/5;
