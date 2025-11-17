function st = create3DStack (Component)

planes = Component.Planes;
nz = size(planes,1);
if nz >0,
    nx = size(planes{1},1);
    ny = size(planes{1},2);
    st = zeros(nx,ny,nz);
    for i=1:nz,  st(:,:,i) = planes{i}; end
end