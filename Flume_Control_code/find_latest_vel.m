function [umean, ustd] = find_latest_vel

fnames = dir(['C:\Users\ControlSystem\Documents\vertfoil\Experiments\Vector\','*.vea']);

fnames = fnames([fnames.bytes]>5000);
[~,idx] = sort([fnames.datenum]);
fnames = fnames(idx);

 fid = load(['C:\Users\ControlSystem\Documents\vertfoil\Experiments\Vector\',fnames(end).name]);
    Ux =  fid(:,19);
    t = [0];
%     Ux = 0.5;
    Uy = fid(:,20);
    Uz = fid(:,21);
    v = 0;
    
    umean = trimmean(sqrt(Ux.^2+Uy.^2+Uz.^2),10);
    
    ustd = std(sqrt(Ux.^2+Uy.^2+Uz.^2));
end