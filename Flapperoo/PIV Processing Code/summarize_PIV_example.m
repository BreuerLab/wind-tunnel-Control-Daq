% Process all of the PIV data, to get mean fields
%
% Original: SHAO 2022
% Modified by: Ronan Gissler 2024
% demo of piv summary

clear
close all

% Add the READIMX library, and set the delimiter
if ismac
    addpath('./readimx_MAC');
    DELIM = '/';
elseif ispc
    addpath('.\readimx_WIN');
    DELIM = '\';
end


%% This is the root directory to read the data files
ROOTDIR = 'R:\ENG_Breuer_Shared\rgissler\PIV\04_02_2024_Turbulence_Grid\Turbulence_Grid_04_02_2024\';

%% This is a list of sub-directorys to process
% SUBDIR_LIST = { ...
%     'M1_S2\SideBySide_PIV_MPd(3x32x32_50%ov_ImgCorr)_GPU_Process_(1-1000)' ...
%     'M1_S3\SideBySide_PIV_MPd(3x32x32_50%ov_ImgCorr)_GPU_Processfinal_(1-1000)_01' ...
%     'M2_S2\1000_imagepairs' ...
%     'M2_S3\1000_imagepairs' ...
%     'M3_S1\1000_imagepairs' ...
%     'M3_S2\1000_imagepairs' ...
%     'M3_S3\1000_imagepairs' ...
%     'R1_S1\SideBySide_PIV_MPd(3x32x32_50%ov_ImgCorr)_GPU_Processfinal_(1-1000)' ...
%     'R1_S2\SideBySide_PIV_MPd(3x32x32_50%ov_ImgCorr)_GPU_Processfinal_(1-1000)' ...
%     'R1_S3\SideBySide_PIV_MPd(3x32x32_50%ov_ImgCorr)_GPU_Processfinal_(1-1000)' ...
%     'R2_S1\SideBySide_PIV_MPd(3x32x32_50%ov_ImgCorr)_GPU_Processfinal_(1-1000)' ...
%     'R2_S2\1000_imagepairs' ...
%     'R2_S3\1000_imagepairs' ...
%     'R3_S1\1000_imagepairs' ...
%     'R3_S2\1000_imagepairs' ...
%     'R3_S3\1000_imagepairs' ...
%     }

SUBDIR_LIST = {...
    'Empty_6m.s\SideBySide_PIV_MPd(4x24x24_75%ov_ImgCorr)_GPU'...
    'Fractal_Grid_6m.s\SideBySide_PIV_MPd(4x24x24_75%ov_ImgCorr)_GPU'...
    'Fractal_Grid_Far_6m.s\SideBySide_PIV_MPd(4x24x24_75%ov_ImgCorr)_GPU'...
    'Rect_Grid_6m.s\SideBySide_PIV_MPd(4x24x24_75%ov_ImgCorr)_GPU'...
    };

Nmax = 50000;

%% Loop through every subdirectory
for i = 1:length(SUBDIR_LIST)
    SUBDIR = SUBDIR_LIST{i};  % Get the sub-directory
    
    FULLPATH = [ROOTDIR SUBDIR DELIM];  % The full path  of the subdirectory
    
    OUTPUT_FILE = SUBDIR(1:5); % The name of the output file is the same as the subdir
    
    disp(['Starting on Directory ' FULLPATH])
    
    lv_dirlist = dir(FULLPATH);  % Get all the files in the subdirectory
    
    N=0;  % Count the number of processed frames
    clear A;
    

    for lv_i=1:size(lv_dirlist,1)  % look through every file in the subdirectory
        
        disp(['Checking: ' lv_dirlist(lv_i).name ' ...'] );
        
        % Check to see if the file that you have is a
        % directory, and make sure that the first letter is "B" which
        % means its a data file
        if ( ~lv_dirlist(lv_i).isdir  && lv_dirlist(lv_i).name(1) == 'B')
            disp(['File: ' lv_dirlist(lv_i).name ' ...'] );
            
            % Read in the data structure from the IMX file
            % The data structre has the velocity field,
            % correlation value, valid flag and x,y
            % coordionates for the entire PIV field
            A = readimx([FULLPATH lv_dirlist(lv_i).name]);
            
            % Get
            D = create2DVec( A.Frames{1} );
            N = N+1;
            
            if (N == 1)
                U1 = zeros(size(D.U));
                U2 = zeros(size(D.U));
                V1 = zeros(size(D.U));
                V2 = zeros(size(D.U));
                UV = zeros(size(D.U));
                CR = zeros(size(D.U));
                Ng = zeros(size(D.U));
            end
            
            valid = find(D.isValid == 1);
            U1(valid) = U1(valid) + D.U(valid);
            U2(valid) = U2(valid) + D.U(valid).* D.U(valid);
            V1(valid) = V1(valid) + D.V(valid);
            V2(valid) = V2(valid) + D.V(valid).* D.V(valid);
            UV(valid) = UV(valid) + D.U(valid).* D.V(valid);
            Ng(valid) = Ng(valid) + 1;             % number of valid
            CR(valid) = CR(valid) + D.Corr(valid); % corr.
        end
        
        % Break if we have reached the max
        if N == Nmax
            break
        end
    end
    
    %% Adjust axes
    x = D.X + 0;
    y = D.Y + 0;
    
    %% Compute statistics
    uave =  U1./Ng;
    vave =  V1./Ng;
    urms = (U2./Ng - (uave).^2).^0.5;
    vrms = (V2./Ng - (vave).^2).^0.5;
    uv   = (UV./Ng - (uave.*vave));
    corr = CR./Ng;
    good = Ng/N;
    
    %% Calculate the freestream from the top
    % U0 = uave(50,15);
    % 
    % % Normalize
    % uave = uave/U0;
    % urms = urms/U0;
    % vave = vave/U0;
    % vrms = vrms/U0;
    % uv   = uv/U0/U0;
    
    %% Plot
    plot_axis=[];
    figure
    
    ax(1) = subplot(4,2,1);
    pcolor(x, y, uave);
    shading(ax(1), 'interp');
    clim([min(uave,[],'all') max(uave,[],'all')]);
    colormap(ax(1), jet);
    colorbar;
    axis(plot_axis);
    title('Streamwise velocity, <u>')
    
    ax(2) = subplot(4,2,2);
    pcolor(x, y, vave);
    shading(ax(2), 'interp');
    clim([min(vave,[],'all') max(vave,[],'all')]);
    colormap(ax(2), jet);
    colorbar;
    axis(plot_axis);
    title('Vertical velocity, <v>')
    
    ax(3) = subplot(4,2,3);
    pcolor(x, y, urms);
    shading(ax(3), 'interp');
    clim([min(urms,[],'all') max(urms,[],'all')]);
    colormap(ax(3), jet);
    colorbar;
    axis(plot_axis);
    title('Streamwise fluctuations, u''')
    
    ax(4) = subplot(4,2,4);
    pcolor(x, y, vrms);
    shading(ax(4), 'interp');
    clim([min(vrms,[],'all') max(vrms,[],'all')]);
    colormap(ax(4), jet);
    colorbar;
    axis(plot_axis);
    title('Vertical fluctuations, v''')
    
    ax(5) = subplot(4,2,5);
    pcolor(x, y, -uv  );
    shading(ax(5), 'interp');
    clim([min(-uv,[],'all') max(-uv,[],'all')]);
    colormap(ax(5), jet);
    colorbar;
    axis(plot_axis);
    title('Reynolds stress, -<u''v''>')
    
    ax(7) = subplot(4,2,7);
    pcolor(x, y, corr);
    shading(ax(7), 'interp');
    clim([0 1]); colormap(ax(7),jet);
    colorbar;
    axis(plot_axis);
    title('Average PIV correlation')
    
    ax(8) = subplot(4,2,8);
    pcolor(x, y, good);
    shading(ax(8), 'interp');
    clim([0 1]);
    colormap(ax(8), jet);
    colorbar;
    axis(plot_axis);
    title('Fraction of good vectors')
    
    sgtitle(SUBDIR, 'Interpreter', 'none');
    savefig(OUTPUT_FILE);
    
    %% Save the data and figure
    eval(['save ' OUTPUT_FILE ' ROOTDIR SUBDIR OUTPUT_FILE Nmax x y U0 uave vave urms vrms uv corr good']);
    savefig(OUTPUT_FILE);
    % end
    
end