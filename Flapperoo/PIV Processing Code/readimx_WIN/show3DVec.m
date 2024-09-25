function [D] = show3DVec( Frame )
%Display located vector field 
D = create3DVec( Frame );
disp 'quiver3d is to slow'
quiver3(D.X,D.Y,D.Z,D.U,D.V,D.W);

