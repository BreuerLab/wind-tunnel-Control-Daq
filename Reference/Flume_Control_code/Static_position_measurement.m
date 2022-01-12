% Static moment measurement
SaveFolder = 'C:\Users\ControlSystem\Documents\vertfoil\Experiments\1foil\Membrane\Camera_calibration\images_calib_071719';

pitch = 0; %[-2:0.25:2];
h_pos = [-0.05:0.002:0.05]; %-[0:0.002:0.04];  %Unit is in meters
% pitch = [-30:1:-15 -14.5:0.5:14.5 15:1:30];    % pitch angles [deg]
% pitch = -[-2:0.5:14.5 15:1:30];    % pitch angles [deg]
pitch = -pitch;

for ipp = 1:numel(h_pos) % pitch angles from 0 to 30 degrees with interval of 1 degree
    curr_hpos = h_pos(ipp)
    SaveFile = sprintf('Membrane_frame_%d_%2.2f.mat',ipp,curr_hpos);
    %     [out,output_prof] = move_new_pos_3rigs_and_static_measurement([0,0,0,0,theta,0],1,15);
    position = [0,0,0,0,0,curr_hpos];   % Shawn angle, Shawn Y-location, Gromit angle, Gromit Y-location, Wallace angle, Wallach Y-location
    [out,output_prof] = move_new_pos_3rigs_and_static_measurement(position,1,5);
    %plot(out(:,7:8),'DisplayName','out(:,7:8)');
    plot(out(:,6)); hold all
    MeanForce = mean(out(:,7:8))
    button = questdlg('Does everything look OK?');
    while strcmp(button,'No')
        disp('Running again. If problem repeats, please select "Cancel" and check.')
        [out,output_prof] = move_new_pos_3rigs_and_static_measurement(position,1,15);
       % plot(out(:,7:8),'DisplayName','out(:,7:8)');
%         MeanForce = mean(out(:,7:8))
        MeanForce = mean(out(2000:end,7:8))
        button = questdlg('Does everything look OK?');
    end
    
    switch button
        case 'Yes'
%             save([SaveFolder,'\',SaveFile]);
        case 'Cancel'
            return
    end
    
    %     save(sprintf('01262019_NACA0012_U05_swept_10_one_endplate_%d_%2.2f_v2.mat',ipp,theta));
    
end

