function export_plot_gifs(folder_path, gif_name, fps)

%% Generating a single foil gif
folderMain = cd;

% working directory:
folderFigs = folder_path;
cd(folderFigs)

files = dir('*.png');

tot_frames = length(files);
if (tot_frames < 1)
    error("Missing frames for gif animation")
end
% tot_frames = 1181;

frame_range = 1:tot_frames;
frmstep = 1;
% frame_range = [tot_frames:-frmstep:1];
% frame_range = 970:3:1400;

%% Generating the gif

gifname = gif_name + ".gif";

dt = 1 / fps;

numFrame = 0;
for ii = frame_range
    numFrame = numFrame + 1;
    figname = ['frame_' sprintf('%04d', ii) '.png'];
%     figname = ['fig' num2str(ii) '.jpg'];
    Z = imread(figname);
    if length(size(Z)) < 3
        imind = Z;
    else
        [imind,cm] = rgb2ind(Z,256);
        % % invert colormap -------------------------------------------------
        % cm = abs(1-cm);
        % cmRtemp = cm(:,1);
        % cmGtemp = cm(:,2);
        % cmBtemp = cm(:,3);
        % cm = [cmBtemp, cmRtemp, cmRtemp];
        cm(cm<0.05) = 0; % ensures black is actually black
        % cm(cm>0.98) = 1; % ensures white is actually white
    end
    
    if numFrame == 1 
        if length(size(Z)) < 3
            imwrite(Z,gifname,'gif','Loopcount',inf,'DelayTime',dt);
        else
            imwrite(imind,cm,gifname,'gif','Loopcount',inf,'DelayTime',dt);
        end
    else 
        if length(size(Z)) < 3
            imwrite(Z,gifname,'gif','WriteMode','append','DelayTime',dt); 
        else
            imwrite(imind,cm,gifname,'gif','WriteMode','append','DelayTime',dt);
        end
    end

    if (mod(ii, 5) == 0)
        disp("Percent complete: " + (ii / max(frame_range))*100 + " %")
    end
end

%% Return to main directory
cd(folderMain);

end