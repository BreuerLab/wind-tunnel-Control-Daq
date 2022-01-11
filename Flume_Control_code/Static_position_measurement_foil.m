% Static moment measurement
SaveFolder = 'C:\Users\ControlSystem\Documents\vertfoil\Experiments\LEV\Static\long\25';

pitch = [-95:5:-30 -28:2:-20 -19:1:-15 -14:0.5:14 15:1:19 20:2:28 30:5:95];    % pitch angles [deg]
% pitch = [-95:5:95];    % pitch angles [deg]
% pitch = [20:2:28 30:5:60];    % pitch angles [deg]
% pitch = -pitch;

for ipp = 1:numel(pitch) % pitch angles from 0 to 30 degrees with interval of 1 degree
% for ipp = 12
    theta = pitch(ipp)
    SaveFile = sprintf('acrylic_wing_%d_%2.2f.mat',ipp,theta);
    [out,output_prof] = move_new_pos_3rigs_and_static_measurement([0,0,0,0,theta,0],1,25);
%     position = [0,0,0,0,0,curr_hpos];   % Shawn angle, Shawn Y-location, Gromit angle, Gromit Y-location, Wallace angle, Wallach Y-location
%     [out,output_prof] = move_new_pos_3rigs_and_static_measurement(position,1,5);
%     plot(out(:,7:8),'DisplayName','out(:,7:8)');
%     plot(out(:,5)/pi*180); hold all
%     MeanForce = mean(out(:,7:8))
%     button = questdlg('Does everything look OK?');
%     while strcmp(button,'No')
%         disp('Running again. If problem repeats, please select "Cancel" and check.')
%         [out,output_prof] = move_new_pos_3rigs_and_static_measurement([0,0,0,0,theta,0],1,25);
%        % plot(out(:,7:8),'DisplayName','out(:,7:8)');
%         MeanForce = mean(out(:,7:8))
%         button = questdlg('Does everything look OK?');
%     end
    
%     switch button
%         case 'Yes'
%             save([SaveFolder,'\',SaveFile]);
%         case 'Cancel'
%             return
%     end
    save([SaveFolder,'\',SaveFile]);
    
end

