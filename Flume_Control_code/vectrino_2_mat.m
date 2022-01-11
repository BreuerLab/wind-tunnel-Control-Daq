
function [t,Ux, Uy, Uz,v] = vectrino_2_mat(T_start,Length)
% start time is in format [year month day hour minute second]
try
T = datevec(T_start);
T(2,:) = T(1,:);
L_vec = datevec(num2str(Length),'SS.FFF');
T_end = T_start+datenum(0,0,0,0,0,Length);
T(2,[5 6]) = T(2,[5 6]) + L_vec(1,[5 6]);

start_time = str2num(sprintf('%04i%02i%02i%02i%02i%02u',T(1,1),T(1,2),T(1,3),T(1,4),T(1,5),round(T(1,6))));
end_time  = str2num(sprintf('%04i%02i%02i%02i%02i%02u',T(2,1),T(2,2),T(2,3),T(2,4),T(2,5),round(T(2,6))));

stime = datenum(T(1,:));
etime = datenum(T(2,:));


 cwd = 'C:\Users\ControlSystem\Documents\vertfoil\Experiments\Vectrino';
% start_file_name = '20160713052921';
% end_file_name = '20160713055421';

fnames = dir(['C:\Users\ControlSystem\Documents\vertfoil\Experiments\Vectrino\','*.vna']);
fnames = fnames([fnames.bytes]>15);
[~,idx] = sort([fnames.datenum]);
fnames = fnames(idx);


for ii = 1:numel(fnames)
    tstart(ii,1) = str2double(fnames(ii).name(9:22));
end

tstartnum = datenum(num2str(tstart),'yyyymmddHHMMSS');


t_ind = find(tstartnum>T_start & tstartnum< T_end);

if isempty(t_ind)
    pause(2)
    fnames = dir(['C:\Users\ControlSystem\Documents\vertfoil\Experiments\Vectrino\','*.vna']);

    fnames = fnames([fnames.bytes]>15);
    [~,idx] = sort([fnames.datenum]);
    fnames = fnames(idx);

    for ii = 1:numel(fnames)
        tstart(ii,1) = str2double(fnames(ii).name(7:20));
    end
    tstartnum = datenum(num2str(tstart),'yyyymmddHHMMSS');


    t_ind = find(tstartnum>T_start & tstartnum< T_end);

end


if isempty(t_ind)
    t_ind = numel(tstart);
    disp('using last saved vectrino data')
end
t_ind = [t_ind(1)-1; t_ind];


    
fid = load(['C:\Users\ControlSystem\Documents\vertfoil\Experiments\Vectrino\',fnames(t_ind(1)).name]);
% next = str2num(start_file_name);

%initialize struct
% may use wrong colomn...check ascii file and compare to colomns for
% correct values
% v.month = (fid(:,1));
% v.day = (fid(:,2));
% v.year =  (fid(:,3));
% v.hour =  (fid(:,4));
% v.minute = (fid(:,5));
% v.second =  (fid(:,6));
% v.time_stamp = [v.year,v.month, v.day,v.hour, v.minute, v.second];
% v.battery_voltage = fid(:,7); %VDC
% v.sound_speed =  fid(:,11); %m/s
% v.heading = fid(:,9); %degrees
% v.pitch_and_roll =  fid(:,9); %degrees
% v.pressure =  fid(:,15); %m
% v.temperature = fid(:,16); % deg C

sample_start = fid(1,3);
v.t = (fid(:,3)-sample_start)/25;
v.Ux =  fid(:,5); %this may not be the right colomn
v.Uy =  fid(:,6);
v.Uz =  fid(:,7);

for ii = 2:numel(t_ind)
    fid = load(['C:\Users\ControlSystem\Documents\vertfoil\Experiments\Vectrino\',fnames(t_ind(ii)).name]);
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
    
    v.t = [v.t; (fid(:,3)-sample_start)/25];
    v.Ux = [v.Ux; fid(:,5)]; %this may not be the right colomn
    v.Uy = [v.Uy; fid(:,6)];
    v.Uz = [v.Uz; fid(:,7)];
    
%     next = str2num(v.time_stamp(end,:));
    

end

% X = 0:1/32:(1);
% X = X';
% Xlong = repmat(X,1,ceil(Length));
% Xlong = Xlong';
% an = datenum(v.time_stamp);
% ind = find(an-an(1));
% [~,inds] = unique(an);
% Seconds = v.second;
% 
% for ii = 1:numel(inds)-1
%     N = numel(inds(ii):inds(ii+1)-1);
%     if N > 32
%         Seconds(inds(ii):inds(ii+1)-1) = Seconds(inds(ii):inds(ii+1)-1)+(0:1/N:(1-1/N))';
%     else
%     
%     Seconds(inds(ii):inds(ii+1)-1) = Seconds(inds(ii):inds(ii+1)-1)+X(33-N:32);
%     end
% end
% N = numel(Seconds(inds(end):end));
%     if N > 32
%         Seconds(inds(end):end) = Seconds(inds(end):end)+(0:1/N:(1-1/N))';
%     else
%     
%     Seconds(inds(end):end) = Seconds(inds(end):end)+X(1:N);
%     end
% v.second = (Seconds);
% 
%     
% v.time_stamp = [v.year,v.month, v.day,v.hour, v.minute, v.second];
% 
% timenum = datenum(v.time_stamp);
% 
% ind1 = find(timenum > T_start & timenum < datenum(T(2,:)));



% 
% 
% time_rel = v.time_stamp-v.time_stamp(1,:);


file_start_time = datenum(num2str(tstart(t_ind(1))),'yyyymmddHHMMSS');
rel_time(:,6)  =  v.t;
timenum = datenum(rel_time)+file_start_time;

ind1 = find(timenum >= T_start & timenum <= datenum(T(2,:)));
if isempty(ind1)
    ind1 = 1:numel(timenum);
end

t = v.t;
v.time = timenum;

% average U
sum = 0;
N = size(v.Ux);
for j=1:N
sum = sum + v.Ux(j) + v.Uy(j) + v.Uz(j) ;
end
v.U_avg = sum/(N(1)*3);

Ux = -v.Ux(ind1);
Uy = -v.Uy(ind1);
Uz = -v.Uz(ind1);

% save(filename, 'v');
 t = t(ind1)-t(ind1(1));
catch
    disp('Error reading vectrino data, outputting null set')
    t = [0];
    Ux = 0;
    Uy = 0;
    Uz = 0;
    v = 0;
    
end
end