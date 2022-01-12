
function [t,Ux, Uy, Uz,v] = vec_2_mat(T_start,Length)
% start time is in format [year month day hour minute second]
T = datevec(T_start);
T(2,:) = T(1,:);
L_vec = datevec(num2str(Length),'SS.FFF');

T(2,[5 6]) = T(2,[5 6]) + L_vec(1,[5 6]);

start_time = str2num(sprintf('%04i%02i%02i%02i%02i%02u',T(1,1),T(1,2),T(1,3),T(1,4),T(1,5),round(T(1,6))));
end_time  = str2num(sprintf('%04i%02i%02i%02i%02i%02u',T(2,1),T(2,2),T(2,3),T(2,4),T(2,5),round(T(2,6))));

 cwd = 'C:\Users\ControlSystem\Documents\vertfoil\Experiments\Vector\';
% start_file_name = '20160713052921';
% end_file_name = '20160713055421';

fnames = dir([cwd,'*.vea']);
for ii = 1:numel(fnames)
    tstart(ii,1) = str2double(fnames(ii).name(7:20));
end

t_ind = find(tstart>start_time & tstart< end_time);

t_ind = [t_ind(1)-1; t_ind];


    
fid = load([cwd,fnames(t_ind(1)).name]);
% next = str2num(start_file_name);

%initialize struct
% may use wrong colomn...check ascii file and compare to colomns for
% correct values
v.month = (fid(:,1));
v.day = (fid(:,2));
v.year =  (fid(:,3));
v.hour =  (fid(:,4));
v.minute = (fid(:,5));
v.second =  (fid(:,6));
v.time_stamp = [v.year,v.month, v.day,v.hour, v.minute, v.second];
v.battery_voltage = fid(:,7); %VDC
v.sound_speed =  fid(:,11); %m/s
v.heading = fid(:,9); %degrees
v.pitch_and_roll =  fid(:,9); %degrees
v.pressure =  fid(:,15); %m
v.temperature = fid(:,16); % deg C
v.Ux =  fid(:,19); %this may not be the right colomn
v.Uy =  fid(:,20);
v.Uz =  fid(:,21);

T_vec_start = v.time_stamp(1);









% next = str2num(v.time_stamp(end,:));

for ii = 2:numel(t_ind)
    fid = load([cwd,fnames(t_ind(ii)).name]);
%     % % Open .vea ascii files
%     if exist([cwd, '/', num2str(next, '%.f'), '.vea'], 'file');
%         fprintf(['\n',num2str(next, '%.f')]);
%         fid = load([cwd, '/', num2str(next, '%.f'), '.vea']);
%     elseif exist([cwd, '/', num2str(next+1, '%.f'), '.vea'], 'file');
%         fprintf(['\n', num2str(next+1, '%.f')]);
%         fid = load([cwd, '/', num2str(next+1, '%.f'), '.vea']);
%     else
%         %if code exits before reaching end_file_name, struct is still
%         %saved. To view last time stamp, call 'v.time_stamp(end,:)'
%         save(filename, 'v');
%         error(['Could not find files with time ',num2str(next, '%.f'),' or ', num2str(next+1, '%.f'),'.']);
%     end
%     
%     if(fid < 0);
%         error('Could not read vector file.');
%     end
    
    
    % may use wrong colomn...check ascii file and compare to colomns for
    % correct values
    
    v.month = [v.month; (fid(:,1))];
    v.day = [v.day; (fid(:,2))];
    v.year = [v.year; (fid(:,3))];
    v.hour = [v.hour; (fid(:,4))];
    v.minute = [v.minute; (fid(:,5))];
    v.second = [v.second; (fid(:,6))];
    v.time_stamp = [v.year,v.month, v.day,v.hour, v.minute, v.second];
    v.battery_voltage = [v.battery_voltage;fid(:,7)]; %VDC
    v.sound_speed = [v.sound_speed; fid(:,11)]; %m/s
    v.heading = [v.heading; fid(:,9)]; %degrees
    v.pitch_and_roll = [v.pitch_and_roll; fid(:,9)]; %degrees
    v.pressure = [v.pressure; fid(:,15)]; %m
    v.temperature = [v.temperature; fid(:,16)]; % deg C
    v.Ux = [v.Ux; fid(:,19)]; %this may not be the right colomn
    v.Uy = [v.Uy; fid(:,20)];
    v.Uz = [v.Uz; fid(:,21)];
    
%     next = str2num(v.time_stamp(end,:));
    

end

X = 0:1/32:(1);
X = X';
Xlong = repmat(X,1,ceil(Length));
Xlong = Xlong';
an = datenum(v.time_stamp);
ind = find(an-an(1));
[~,inds] = unique(an);
Seconds = v.second;

for ii = 1:numel(inds)-1
    N = numel(inds(ii):inds(ii+1)-1);
    if N > 32
        Seconds(inds(ii):inds(ii+1)-1) = Seconds(inds(ii):inds(ii+1)-1)+(0:1/N:(1-1/N))';
    else
    
    Seconds(inds(ii):inds(ii+1)-1) = Seconds(inds(ii):inds(ii+1)-1)+X(33-N:32);
    end
end
N = numel(Seconds(inds(end):end));
    if N > 32
        Seconds(inds(end):end) = Seconds(inds(end):end)+(0:1/N:(1-1/N))';
    else
    
    Seconds(inds(end):end) = Seconds(inds(end):end)+X(1:N);
    end
v.second = (Seconds);

    
v.time_stamp = [v.year,v.month, v.day,v.hour, v.minute, v.second];

timenum = datenum(v.time_stamp);

ind1 = find(timenum > T_start & timenum < datenum(T(2,:)));





time_rel = v.time_stamp-v.time_stamp(1,:);


t = time_rel(:,6)+time_rel(:,5)*60+time_rel(:,4)*3600;

% average U
sum = 0;
N = size(v.Ux);
for j=1:N
sum = sum + v.Ux(j) + v.Uy(j) + v.Uz(j) ;
end
v.U_avg = sum/(N(1)*3);

Ux = v.Ux(ind1);
Uy = v.Uy(ind1);
Uz = v.Uz(ind1);

% save(filename, 'v');
t = t(ind1)-t(ind1(1));

end