% Run heaving foil at a vector of frequencies
% Gali Alon Tzezana, February 2019
% Assumes system was initialized - daq_setup, flume velocity set, find_zero etc.
% disp('Turn on motor power. Press any key to run find_bias_3rigs');
% find_bias_3rigs;

Date = datetime('today');
Foil = 'Membrane0.2mm';
Location = 'Wallace';
U = 0.5;    % Velocity [m/s]
A = 0.1;  % Heaving amplitude, normalized by chord
theta0 = 0; % Pitching amplitude [deg]
fVec =  1; %[0.25:0.25:3.0]; %[0.1:0.1:3]; %[1.0]; %[0.5:0.25:1]; % [0.2 0.4 0.8 1.6]; %[0.6 1.0]; %[0.2 0.4 0.8 1.6 3]; %

% SaveFolder = 'C:\Users\ControlSystem\Documents\vertfoil\Experiments\1foil\Membrane\Membrane_Heave\In_water\Large_Amp';
SaveFolder = 'C:\Users\ControlSystem\Documents\vertfoil\Experiments\1foil\Membrane\Membrane_Heave\In_water\Camera';
% SaveFolder = 'C:\Users\ControlSystem\Documents\vertfoil\Experiments\1foil\Membrane\\NACA0012_pitch';

if strcmp(Location,'Wallace')
    for iff=1:length(fVec)
        disp(['f=',num2str(fVec(iff)),' Hz']);
        
        SaveFile = [char(Date),'_',Foil,'_U',num2str(U,'%.1f'),'_f',num2str(fVec(iff),'%.2f'),'_h',num2str(A),'_p',num2str(theta0),'.mat'];
%         SaveFile = [char(Date),'_',Foil,'_U',num2str(U,'%.1f'),'_f',num2str(fVec(iff),'%.1f'),'_theta',num2str(theta0,'%.1f'),'.mat'];
        
%                 [flume,out,dat,Prof2,Prof_out] = run_cycle_3rigs_20181002(fVec(iff),0,0,0,0,0,A,0,0,20,0); % Heaving, Wallace
        [flume,out,dat,Prof2,Prof_out] = run_cycle_3rigs_20181002(fVec(iff),0,0,0,0,theta0,A,0,0,20,90); % Pitching & heaving, Wallace
        figure(1);
        plot(out(:,7:12),'DisplayName','out(:,7:12)');
        figure(2);
        plot(out(:,5:6),'DisplayName','out(:,5:6)');
        Means = mean(out(:,7:8))
        button = questdlg('Does everything look OK?');
        while strcmp(button,'No')
            disp('Running again. If problem repeats, please select "Cancel" and check.')
                        [flume,out,dat,Prof2,Prof_out] = run_cycle_3rigs_20181002(fVec(iff),0,0,0,0,theta0,A,0,0,20,90); % Heaving, Wallace
%             [flume,out,dat,Prof2,Prof_out] = run_cycle_3rigs_20181002(fVec(iff),0,0,0,0,theta0,0,0,0,20,0); % Pitching, Wallace
            
        figure(1); hold on
        plot(out(:,7:12),'DisplayName','out(:,7:12)');
        figure(2); hold on
        plot(out(:,5:6),'DisplayName','out(:,5:6)');
        Means = mean(out(:,7:8))
%             MeanThrust = mean(out(:,8))
            button = questdlg('Does everything look OK?');
        end
%         button = 'Yes';
        switch button
            case 'Yes'
                save([SaveFolder,'\',SaveFile]);
            case 'Cancel'
                save([SaveFolder,'\',SaveFile]);
                return
        end
        
    end
else
    warning('Please update script for location different than Wallace!')
    return
end