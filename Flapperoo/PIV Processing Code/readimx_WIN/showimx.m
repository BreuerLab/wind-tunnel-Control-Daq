function [D]=showimx( Frame )
% CALL:      []=showimx(Frame);
%
% FUNCTION:  Displaying data of LaVision's IMX structure
%            (one vector field, all image frames or only single image frame)
%
% ARGUMENTS: Frame  = frames structure created by readimx2 function
%
% RETURN:    in case of images (image type=0):

if nargin==0,
	help showimx, return
end

if ~(isfield(Frame,'Components') & isfield(Frame,'Attributes') & isfield(Frame,'Scales') & isfield(Frame,'ComponentNames')  & isfield(Frame,'IsVector') ) ,
	help showimx, return
end

Components = Frame.Components;
if Frame.IsVector,
    frameInfo = MakeFrameInfo(Frame);
    if ( frameInfo.is3D ), 
		D = show3DVec(Frame);
    else
        D = show2DVec(Frame);
    end
        
else
    Planes = Components{1}.Planes; % assume image in component 1, ignore mask in component 2
    nz = size(Planes,1);
    if nz==0,
        disp('no Planes')
    elseif nz==1,
        D = showPlane( Planes{1}, Frame.Scales );
    else
        D = showVolume( Planes, Frame.Scales );
    end
end