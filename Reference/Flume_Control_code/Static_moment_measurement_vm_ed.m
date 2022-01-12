% Static moment measurement
clearvars
SaveFolder = 'C:\Users\ControlSystem\Documents\vertfoil\Experiments\1foil\Membrane\Static_Blue_Fast50_Slow50_thinner33pc_420micron_lambda01pt1\todel';
if ~exist(SaveFolder,'dir')
    mkdir(SaveFolder);
end

% pitch = -3; %[-2:0.25:2];

% pitch = [-30:1:-15 -14.5:0.5:14.5 15:1:30];    % pitch angles [deg]
% pitch = -[-2:0.5:14.5 15:5:45];    % pitch angles [deg]
pitch = [0];%[-45:2:7]; %[-2:1:45]; %[-2:0.5:14.5 15:1:45];    % pitch angles [deg]
U = 0.5; %mean flow speed in m/s
s = 0.384; %span
c = 0.096; %chord
Ap = s*c;
Date = yyyymmdd(datetime('today'));

for ipp = 1:numel(pitch) % pitch angles from 0 to 30 degrees with interval of 1 degree
    theta = pitch(ipp)
%     SaveFile = sprintf('%d_Blue_Fast50_Slow50_thinner33pc_lambda01pt2_U0.5_%2.2f.mat',Date,theta);
    %     [out,output_prof] = move_new_pos_3rigs_and_static_measurement([0,0,0,0,theta,0],1,15);
    position = [0,0,0,0,theta,0];   % Shawn angle, Shawn Y-location, Gromit angle, Gromit Y-location, Wallace angle, Wallach Y-location
    [out,output_prof] = move_new_pos_3rigs_and_static_measurement(position,1,15);
    Fn = out(:,7);
    Ft = out(:,8);
    Tz = out(:,12);
    FL(ipp) = mean(Fn)*cosd(theta) - mean(Ft)*sind(theta);
    thet_vect(ipp) = theta;
    CL(ipp) = FL(ipp)/(0.5*1000*U^2*Ap)
     CM(ipp) = mean(Tz(ipp))/(0.5*1000*U^2*Ap*c)
    %plot(out(:,7:8),'DisplayName','out(:,7:8)');
    MeanForce = mean(out(:,7:12))
%     button = questdlg('Does everything look OK?');
%     while strcmp(button,'No')
%         disp('Running again. If problem repeats, please select "Cancel" and check.')
%         [out,output_prof] = move_new_pos_3rigs_and_static_measurement(position,1,15);
%         plot(out(:,7:8),'DisplayName','out(:,7:8)');
%         MeanForce = mean(out(:,7:8))
%         button = questdlg('Does everything look OK?');
%     end
%     
%     switch button
%         case 'Yes'
%             save([SaveFolder,'\',SaveFile]);
%         case 'Cancel'
%             save([SaveFolder,'\',SaveFile]);
%             return
%     end
%     save([SaveFolder,'\',SaveFile]);
    %         save(sprintf('01262019_NACA0012_U05_swept_10_one_endplate_%d_%2.2f_v2.mat',ipp,theta));
    
end
    SaveFile = sprintf('%d_Blue_Fast50_Slow50_thinner33pc_420micron_lambda01pt1_U0.5_static.mat',Date);

    save([SaveFolder,'\',SaveFile]);

    
figure(2), plot(thet_vect,CL,'o')
figure(3), plot(thet_vect,CM,'*')
