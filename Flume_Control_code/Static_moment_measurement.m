% Static moment measurement
SaveFolder = 'C:\Users\ControlSystem\Documents\vertfoil\Experiments\1foil\Membrane\Static_rigid_plate';
if ~exist(SaveFolder,'dir')
    mkdir(SaveFolder);
end

% pitch = -3; %[-2:0.25:2];

% pitch = [-30:1:-15 -14.5:0.5:14.5 15:1:30];    % pitch angles [deg]
% pitch = -[-2:0.5:14.5 15:5:45];    % pitch angles [deg]
pitch = [-2:0.5:14.5 15:1:45];    % pitch angles [deg]

Date = yyyymmdd(datetime('today'));

for ipp = 1:numel(pitch) % pitch angles from 0 to 30 degrees with interval of 1 degree
    theta = pitch(ipp)
    SaveFile = sprintf('%d_FlatPlate_U0.5_%d_%2.2f.mat',Date,ipp,theta);
    %     [out,output_prof] = move_new_pos_3rigs_and_static_measurement([0,0,0,0,theta,0],1,15);
    position = [0,0,0,0,theta,0];   % Shawn angle, Shawn Y-location, Gromit angle, Gromit Y-location, Wallace angle, Wallach Y-location
    [out,output_prof] = move_new_pos_3rigs_and_static_measurement(position,1,15);
    plot(out(:,7:8),'DisplayName','out(:,7:8)');
    MeanForce = mean(out(:,7:8))
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
    save([SaveFolder,'\',SaveFile]);
    %         save(sprintf('01262019_NACA0012_U05_swept_10_one_endplate_%d_%2.2f_v2.mat',ipp,theta));
    
end

