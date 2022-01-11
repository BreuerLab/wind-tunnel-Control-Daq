function foil = calc_single_foil(params,number_of_cycles,dat,out,path_name, avg_vel)
% calculates forces and saves data to standard format 
% (V3 1/6/2016 -Michael and Jen)
% Data mus tbe of form 
% freq: frequency (Hz)
% pitch: pitch amplitude (degrees)
% Heave: heave amplitude (meters)
% number_of_cycles: number of cycles input
% dat: raw experimental voltage/counter data
% out: output of output_conv
% path_name: string of path to folder where data should go.

global s last_out pitch_offset1  run_num flume_hertz Wbias  chord span foil_shape Temperature foil_separation new_param pos Wall_distance_left Wall_distance_right pitch_axis

freq = params(1);
pitch = params(2);
heave = params(3);
phase12 = params(4);
phase13 = params(5);
if numel(params) == 6
    phi = params(6);
else
    phi = 90;
end


run_date = date;
rate = s.Rate;
t = 0:1/rate:(numel(out(:,1))-1)/rate;
t = t';
%% Calculate forces 
%     M(:,1) = 1.04; %3 inch x 5/16 inch rectangular clear plate (8/2/2018)
%     I(:,1) = 0.000645;  %3 inch x 5/16 inch rectangular clear plate (8/2/2018)

%     M(:,1) = 1.398; %3 inch x 5/16 inch rectangular aluminum (1/7/2016 -Michael)
%     I(1,1) = 0.00145;  %10 cm x 5/16 inch rectangular aluminum  (4/7/2016 -Michael)

%     M(:,1) = 1.82; % 10 cm x 35 cm Triangular with enplates (8/2/2018)
%     I(:,1) = 0.0025; % 10 cm x 35 cm Triangular with enplates (8/2/2018)

%     M(:,1) = 1.26; % 10 cm x 35 cm elliptical with enplates (8/2/2018)
%     I(:,1) = 0.0021; % 10 cm x 35 cm elliptical with enplates (8/2/2018)
    
    M(:,1) = 1.050; % 10 cm x 35 cm elliptical without enplates (8/2/2018)
    I(:,1) = 0.000686; %10 cm x 35 cm elliptical without enplates (8/2/2018)
    
%     M(:,1) = 1.86; % 10 cm x 35 cm Rect with enplates (8/2/2018)
%     I(:,1) = 0.00251; % 10 cm x 35 cm Rect with enplates (8/2/2018)

%     M(:,1) = 2.27; % 10 cm x 45 cm rect with enplates (6/8/2017)
%     I(:,1) = 0.0029; % 10 cm x 45 cm rect with enplates (6/8/2017)  



    v = out(:,9:11);
    v(:,3) = (out(:,11)+out(:,12))/2;
    for ii = 1:3
        V(ii) = trimmean(v(:,ii),10);
        S(ii) = std(v((abs(v(:,ii)-mean(v(:,ii)))<2*std(v(:,ii))),ii));
    end
    fs_vel =sqrt(V(1)^2+V(2)^2+V(3)^2); %Velocity magnitude
    fs_vel = avg_vel(1); % Change to include std!
    fs_std = sqrt(S(1)^2+S(2)^2+S(3)^2); %Velocity standard deviation
    fs_std=avg_vel(2);%S(2);
    if fs_vel >0.9
        fs_vel = 1;
        fs_std = 1;
    end
    smooth_fac = 1;

    
    
    p(:,1) = out(:,1);
    pv(:,1) = diff([out(1,1);out(:,1)])*rate;
    pa(:,1) = smooth(diff([out(1,1);smooth(out(:,1),10);out(end,1)],2).*rate^2,10);
    pfilt(:,1) = low_pass_filtfilt(out(:,1));
    plowfilt(:,1) = lowlow_pass_filtfilt(out(:,1));
    pvfilt(:,1) = diff([pfilt(1,1);pfilt(:,1)])*rate;
        pafilt(:,1) = diff([pfilt(1,1);pfilt(:,1);pfilt(1,1)],2)*rate^2;
%     pafilt(:,1) = diff([pfilt(1,1);pfilt(:,1);plowfilt(1,1)],2)*rate^2;


    h(:,1) = out(:,2);
    hv(:,1) = diff([out(1,2);out(:,2)],1).*rate;
    ha(:,1) = smooth(diff([out(1,2);smooth(out(:,2),10);out(end,2)],2).*rate^2,10);
    hfilt(:,1) = low_pass_filtfilt(out(:,2));
    hlowfilt(:,1) = lowlow_pass_filtfilt(out(:,2));
    hvfilt(:,1) = diff([hfilt(1,1);hfilt(:,1)])*rate;
    hafilt(:,1) = diff([hlowfilt(1,1);hlowfilt(:,1);hlowfilt(1,1)],2).*rate^2;
    
if ~sum(out(:,3))
    Lift = out(:,3);
    Drag = out(:,3);
    Torque = out(:,3);
else
%     Lift(:,1) = out(:,3).*cos(out(:,1))-out(:,4).*sin(out(:,1))+M(:,1)*hafilt(:,1)
%     Drag(:,1) = out(:,3).*sin(out(:,1))+out(:,4).*cos(out(:,1));
%     Torque(:,1) = smooth(out(:,8),20)+smooth(I(1,1)*pafilt(:,1),20);
%     Lift(:,1) = low_pass_filtfilt(out(:,3).*cos(pfilt(:,1))-out(:,4).*sin(pfilt(:,1)))+M(:,1)*hafilt(:,1);
%     Drag(:,1) = low_pass_filtfilt(out(:,3).*sin(pfilt(:,1))+out(:,4).*cos(pfilt(:,1)));
%     Torque(:,1) = low_pass_filtfilt(out(:,8))-I(1,1)*pafilt(:,1);
    
    Lift(:,1) = (out(:,3).*cos(pfilt(:,1))-out(:,4).*sin(pfilt(:,1)))+M(:,1)*ha(:,1);
    Drag(:,1) = (out(:,3).*sin(pfilt(:,1))+out(:,4).*cos(pfilt(:,1)));
    Torque(:,1) = out(:,8)+I(1,1)*pafilt(:,1);
    
%     Lift(:,1) = medfilt1(Lift,4);
%     Drag(:,1) = medfilt1(Drag,4);
%     Torque(:,1) = medfilt1(Torque,4);
    
end

    CL(:,1) = Lift(:,1)/(.5*1000*fs_vel.^2*chord*span);
    CD(:,1) = Drag(:,1)/(.5*1000*fs_vel.^2*chord*span);
    CT(:,1) = Torque(:,1)./(.5*1000*fs_vel.^2*span*chord.^2);
    %% 
    
    
    
    centerToWallTop = Wall_distance_left;
    centerToWallBot = Wall_distance_right;
    run_date = date;
    

    
    sf=rate;
    fnorm=30/(sf/2);
%     [b1,a1]=butter(6,fnorm,'low');
    
%     clear Lift
%     smooth_fac = rate/100;
%     out(:,1)=-out(:,1);
%     ha =filtfilt(b1,a1,diff( ([out(:,1); out(end,1) ;out(end,1)]).*rate^2,2));
%     ha1=smooth(diff( ([out(:,1); out(end,1) ;out(end,1)]).*rate^2,2),smooth_fac*5);
%     Lift1 = (smooth(out(:,3).*cos(out(:,2))-(out(:,4)).*sin(out(:,2)),smooth_fac*5)+M*smooth(ha1,smooth_fac*4));
%     Lift = (filtfilt(b1,a1,out(:,3).*cos(out(:,2))-(out(:,4)).*sin(out(:,2)))+M*ha);

%period*rate=data points per cycle, points per cycle * number of cycles
%     if ~heave  %if there is no heave, base cycle on pitch
%         pitch_pos = plowfilt;
%         bdc = min(pitch_pos); %bottom dead center will become zero
%         pitch_pos = pitch_pos+abs(bdc);
%         crop_start = round(1./freq(1)*rate*(round(number_of_cycles/2)));%crop first half of cycles
%         start_value = knnsearch(pitch_pos(crop_start:crop_start+round(1./freq(1)*rate)),0);%find value closest to zero after the start
%         start_value = crop_start + start_value; %select the index to begin at
%         range = (start_value:start_value+round(1./freq(1)*rate*(floor(number_of_cycles/2)+1)));
%     else
cycle_start = 4;

    heave_pos = h;
    bdc = min(heave_pos); %bottom dead center will become zero
    heave_pos = heave_pos+abs(bdc);
    crop_start = round(1./freq(1)*rate*(cycle_start));%crop first half of cycles
    start_value = knnsearch(heave_pos(crop_start:crop_start+round(1./freq(1)*rate)),0);%find value closest to zero after the start
%     start_value = 0;
    start_value = crop_start + start_value; %select the index to begin at
    range = (start_value:start_value+round(1./freq(1)*rate*(number_of_cycles-cycle_start)));
%     end
%     %range=round(1./freq(1)*rate*(round(number_of_cycles/2))):round(1./freq(1)*rate*(number_of_cycles+1));
    sub_dat(:,1)=pfilt(range,1);
    sub_dat(:,2)=hfilt(range,1);
%     sub_dat(:,3)=filtfilt(b1,a1,Torque(range,1));
%     sub_dat(:,4)=filtfilt(b1,a1,Lift(range,1));
    sub_dat(:,3)=Torque(range,1);
    sub_dat(:,4)=Lift(range,1);
    sub_dat(:,5:8)=out(range,9:12);
    tt=t(range);
    vel = fs_vel;
    
    smooth_factor = 1;
    t = t(range(1:end-1));
    pitch_pos1 = out(range(1:end-1),1);
%     pitch_pos2 = out(range(1:end-1),3);
    heave_pos1 = out(range(1:end-1),2)+abs(min(out(range(1:end-1),2)));
%     heave_pos2 = out(range(1:end-1),4)+abs(min(out(range(1:end-1),4)));
    Torque = [smooth(Torque(range(1:end-1),1),smooth_factor)];
    Drag = [smooth(Drag(range(1:end-1),1),smooth_factor)];
    Lift = [smooth(Lift(range(1:end-1),1),smooth_factor)];
    

% [eff1,eff_std1,vel,fs_std,pitch_vel,heave_vel,p_inst_power,h_inst_power,t_inst_power,eff_inst,pp_cycle,hp_cycle,tp_cycle,Yp,eta]=calc_eff_single_foil(sub_dat,pitch_axis,span,chord,rate,freq);
    %     [eff,p_eff,h_eff,coeff,p_coeff,h_coeff,fs_vel,fs_std,t_power,p_power,h_power,w_power,max_y,eff_std,p_eff_std,h_eff_std,max_eaoa,refreq,eff2,p_eff2,h_eff2,coeff2,p_coeff2,h_coeff2,t_power2,p_power2,h_power2,w_power2,max_y2,eff_std2,p_eff_std2,h_eff_std2,max_eaoa2,refreq2]=calc_eff_tandem(dat,pitch_axis,span,chord,rate,freq)


    
    rho = 1000;
    p_vel = pv(range(1:end-1),1);
    h_vel = hv(range(1:end-1),1);
    pitch_vel = p_vel;%lowlow_pass_filtfilt(p_vel);
heave_vel = [h_vel];
p_inst_power=p_vel.*Torque;
h_inst_power=h_vel.*Lift;

t_inst_power = p_inst_power + h_inst_power;

p_power=trapz(p_inst_power)./length(p_inst_power);
h_power=trapz(h_inst_power)./length(h_inst_power);


t_power=p_power+h_power;
thrust = -trapz(Drag)./length(Drag);
Ux = v(range,1);
Uy = v(range,2);
Uz = v(range,3);

%% finding the standard deviation across the cycles
num=floor(length(p_inst_power)/(1/freq(1)*rate));
T=floor(1/freq(1)*rate);
for i=1:num
    p_a(i)=mean(p_inst_power(1+(i-1)*T:T*i));
    h_a(i)=mean(h_inst_power(1+(i-1)*T:T*i));
    p_a_instc(:,i) = p_inst_power(1+(i-1)*T:T*i);
    h_a_instc(:,i) = h_inst_power(1+(i-1)*T:T*i);
   
end
p_inst_mean = mean(p_a_instc,2);
p_inst_std = std(p_a_instc',1).';
h_inst_mean = mean(h_a_instc,2);
h_inst_std = std(h_a_instc',1).';
t_inst_mean = p_inst_mean+h_inst_mean;
t_inst_std = p_inst_std+h_inst_std;
t_a=p_a+h_a;
p_a_std=std(p_a);
h_a_std=std(h_a);
t_a_std=std(t_a);




tp_cycle = [t_a];
pp_cycle = [p_a];
hp_cycle = [h_a];
%% Calculate Efficiency
% get max swept area
pitch_amp=pfilt;
heave_amp=hfilt;

% Maximum swept area calculation 
max_y_le=max(2.*heave_amp+2*pitch_axis*chord.*sin(pitch_amp)); 
max_y_te=max(2.*heave_amp-2*(1-pitch_axis)*chord.*sin(pitch_amp));
max_y=max([max_y_le max_y_te]);

%swept_area=span*max_y;


Yp = [max_y ]/chord;
swept_area = [max_y]*span;

% approximate version,efficiency of power extraction
w_power=0.5*rho*fs_vel^3*swept_area(1);

% power extraction ability of the foil
w_foil=0.5*rho*fs_vel^3*chord*span;

%efficiency
eff_inst = t_inst_power./w_power;

eta(:,1) = t_a/w_power;
eff1=t_power/w_power;
p_eff=p_power./w_power;
h_eff=h_power./w_power;


eff_std1=t_a_std/w_power;
p_eff_std=p_a_std/w_power;
h_eff_std=h_a_std/w_power;


%coefficient
coeff=t_power/w_foil;
p_coeff=p_power./w_foil;
h_coeff=h_power./w_foil;


% maxmum effective angle of attack
% [aoa_le]=eff_aoa_new(dat(:,1:2),fs_vel,rate);
% max_eaoa=max(abs(aoa_le));
% [aoa_le2]=eff_aoa_new(dat(:,9:10),fs_vel,rate);
% max_eaoa2=max(abs(aoa_le2));
max_eaoa2=0;
max_eaoa=0;
%reduced frequency
refreq=freq(1)*chord/fs_vel;
    %   
        T = (1/freq(1)*rate);
    N = length(eff_inst)/T;
    %% DEFINING OUTPUTS
    
    foil = struct();
    % = struct();
    
    %Flume Specifics
    foil.U_inf = fs_vel;
    foil.U_inf_std = fs_std;
    %.U_inf = fs_vel;
    foil.chord = chord;
    %.chord = chord;
    foil.span = span;
    %.span = span;
    foil.temperature = Temperature;
    %.temperature = Temperature;
    foil.freq_Hz = freq(1);
    %.freq_Hz = freq(2);
    foil.sampling_rate = rate;
    %.sampling_rate = rate/10;
    foil.pitch_axis = pitch_axis;
    foil.flume_speed_Hz = flume_hertz;
    foil.input = params;
    
    
if ~foil.U_inf || foil.U_inf_std > .1
        path_name = [path_name,'no_flow\'];        
end

reduction_factor = 1;

    %Shared Specifics
    foil.Re = fs_vel*chord/1.004E-6;
    %%.Re =
    foil.foil_geometry = foil_shape;
    %.foil_geometry = foil_shape;
    foil.data_location = path_name;
    %.data_location = data_location;
    foil.date = run_date;
    %.date = date;
%     foil.dat = dat;
    foil.Mass_kg = M; %Mass of the foil for interial calculation 
    foil.Inertial_Moment_kgm2 = I;  %Moment of inertia of the foil in kg m^2
    foil.Number_of_cycles = (floor(number_of_cycles/2)+1);
    foil.Cycle_start_inds = 1:round(1./freq(1)*rate):round(1./freq(1)*rate*(floor(number_of_cycles/2)+1));
    foil.time_range = [range(1) range(end)]/1000; % range of in seconds
    %Basic Kinematics (Sinusoidal)
    foil.freq = freq(1)*chord/vel;
    %.freq = freq(2)*chord/round(vel,1);
    foil.heave_amp = heave(1)/chord;
    %.heave_amp = heave(2)/chord;
    foil.pitch_amp = pitch(1);
    %.pitch_amp = pitch(2);
    foil.phi = phi;
%     foil.phi = 90;
    
    %Specific for mult foil cases
    foil.absolute_phase = 0;
    %.absolute_phase = round(phase*180/pi);
    foil.Delta_x = 0;
    %.Delta_x = foil_separation/chord;
    foil.Delta_y = 0;
    %.Delta_y = 0;
    
    %Specific for wall cases
    foil.centerToWallTop = centerToWallTop;
    %.centerToWallTop = NaN;
    foil.centerToWallBot = centerToWallBot;
    %.centerToWallBot = NaN;

    %Time dependent outputs
    foil.t = (t(1:reduction_factor:end)-t(1))*fs_vel/chord;
    foil.t_sec = t(1:reduction_factor:end)-t(1); %time in seconds
    foil.t_cycle =(t(1:reduction_factor:end)-t(1))*foil.freq_Hz; %t=1 at 1 cycle
    %.t = (t(1:reduction_factor:end)-t(1))*fs_vel/chord;
    foil.pitch_pos = pitch_pos1(1:reduction_factor:end);
    %.pitch_pos = pitch_pos2(1:reduction_factor:end);
    foil.pitch_vel = pitch_vel(1:reduction_factor:end,1)*chord/fs_vel;
    %.pitch_vel = pitch_vel(1:reduction_factor:end,2)*chord/fs_vel;
    foil.heave_pos = heave_pos1(1:reduction_factor:end)/chord;
    %.heave_pos = heave_pos2(1:reduction_factor:end)/chord;
    foil.heave_vel = -heave_vel(1:reduction_factor:end,1)/fs_vel;
    %.heave_vel = -heave_vel(1:reduction_factor:end,2)/fs_vel;
    foil.heave_acc = ha(range,1);
    foil.pitch_acc = pafilt(range,1);
    
    foil.torque = Torque(1:reduction_factor:end,1)/(0.5*rho*fs_vel^2*span*chord^2);
    foil.torque_Nm =  Torque(1:reduction_factor:end,1);
    %.torque = Torque(1:reduction_factor:end,2)/(0.5*rho*fs_vel^2*span*chord^2);
    foil.drag = Drag(1:reduction_factor:end,1)/(0.5*rho*fs_vel^2*span*chord);
    foil.drag_N = Drag(1:reduction_factor:end,1);
    %.drag = Drag(1:reduction_factor:end,2)/(0.5*rho*fs_vel^2*span*chord);
    foil.lift = Lift(1:reduction_factor:end,1)/(0.5*rho*fs_vel^2*span*chord);
    foil.lift_N = Lift(1:reduction_factor:end,1);
    %.lift = -Lift(1:reduction_factor:end,2)/(0.5*rho*fs_vel^2*span*chord);
    foil.pitch_power = p_inst_power(1:reduction_factor:end,1)/(0.5*rho*fs_vel^3*chord*span);
    foil.pitch_power_W = p_inst_power(1:reduction_factor:end,1);
    %.pitch_power = p_inst_power(1:reduction_factor:end,2)/(0.5*rho*fs_vel^3*chord*span);
    foil.heave_power = h_inst_power(1:reduction_factor:end,1)/(0.5*rho*fs_vel^3*chord*span);
    foil.heave_power_W = h_inst_power(1:reduction_factor:end,1);
    %.heave_power = h_inst_power(1:reduction_factor:end,2)/(0.5*rho*fs_vel^3*chord*span);
    foil.total_power = t_inst_power(1:reduction_factor:end,1)/(0.5*rho*fs_vel^3*chord*span);
    foil.total_power_W = t_inst_power(1:reduction_factor:end,1);
    %.total_power = t_inst_power(1:reduction_factor:end,2)/(0.5*rho*fs_vel^3*chord*span);
    foil.efficiency_inst = eff_inst(1:reduction_factor:end,1);
    %.efficiency_inst = eff_inst(1:reduction_factor:end,2);
    foil.pitch_power_mean = [p_inst_mean p_inst_std];
    foil.heave_power_mean = [h_inst_mean h_inst_std];
    foil.t_power_mean = [t_inst_mean t_inst_std];
    foil.Ux = Ux(1:reduction_factor:end,1);
    foil.Uy = Uy(1:reduction_factor:end,1);
    foil.Uz = Uz(1:reduction_factor:end,1);
    %Post-processed outputs
    foil.Yp = Yp(1);
    %.Yp = Yp(2);
    foil.eta = eta(:,1);
    %.eta = eta(:,2);
    foil.eta_mean = mean(eta(:,1));
    %.eta_mean = mean(eta(:,2));
    foil.eta_std = std(eta(:,1));
    %.eta_std = std(eta(:,2));
    foil.power = -t_power;
    foil.thrust = thrust;
    foil.CT = thrust./(.5*1000*fs_vel^2*chord*span);
    foil.CP = -t_power./(.5*1000*fs_vel^3*chord*span);
    foil.N = N;
    %.N = N;
    
    
    red_freq1 = freq(1)*chord/round(vel,2);
    foil.absolute_phase11 = 0;
    foil.absolute_phase12 = round(phase12*180/pi);
    foil.absolute_phase13 = round(phase13*180/pi);
    foil.Delta_x11 = 0;
    foil.Delta_x12 = foil_separation/chord;
    foil.Delta_x13 = foil_separation/chord;
    foil.Delta_y11 = 0;
    foil.Delta_y12 = 0;
    foil.Delta_y13 = 0;
    heave = heave/chord;
    f_disp = sprintf('%d',round(red_freq1*100));
    nd_t = t*fs_vel/chord;
    rho = 1000;
    nd_heave_pos1 = heave_pos1/chord;
    nd_heave_vel = heave_vel/fs_vel;
    
%     %NEED pitch_vel and down on list
%     foil = struct('t',t(1:10:end,1),'pitch_pos',pitch_pos1(1:10:end),'pitch_vel',pitch_vel(1:10:end,1),'heave_pos',heave_pos1(1:10:end),'heave_vel',heave_vel(1:10:end,1),'torque',Torque(1:10:end,1),'drag',Drag(1:10:end,1),'lift',Lift(1:10:end,1),'pitch_power',p_inst_power(1:10:end,1),'heave_power',h_inst_power(1:10:end,1),'total_power',t_inst_power(1:10:end,1),'efficiency_inst',eff_inst(1:10:end,1),'absolute_phase',absolute_phase1,'efficiency',eff1,'efficiency_std',eff_std1,'red_freq',red_freq1,'heave',heave(1),'pitch',pitch(1),'phi',pi/2,'freq',freq(1),'U_inf',fs_vel,'U_inf_std',fs_std,'chord',chord,'span',span,'temperature',Temperature,'centerToWallTop',NaN,'centerToWallBot',NaN,'foil_geometry',foil_shape,'Delta_x',Delta_x1, 'Delta_y',Delta_y1,'data_location',data_location,'date_compiled',date,'nd_t',nd_t(1:10:end),'nd_lift',nd_lift(1:10:end,1),'nd_torque',nd_torque(1:10:end,1),'nd_heave_pos',nd_heave_pos1(1:10:end),'nd_heave_vel',nd_heave_vel(1:10:end,1),'run_date',run_date,'pp_cycle',pp_cycle(1,:),'hp_cycle',hp_cycle(1,:),'tp_cycle',tp_cycle(1,:));
%     % = struct('t',t(1:10:end,1),'pitch_pos',pitch_pos2(1:10:end),'pitch_vel',pitch_vel(1:10:end,2),'heave_pos',heave_pos2(1:10:end),'heave_vel',heave_vel(1:10:end,2),'torque',Torque(1:10:end,2),'drag',Drag(1:10:end,2),'lift',Lift(1:10:end,2),'pitch_power',p_inst_power(1:10:end,2),'heave_power',h_inst_power(1:10:end,2),'total_power',t_inst_power(1:10:end,2),'efficiency_inst',eff_inst(1:10:end,2),'absolute_phase',absolute_phase2,'efficiency',eff2,'efficiency_std',eff_std2,'red_freq',red_freq2,'heave',heave(2),'pitch',pitch(2),'phi',pi/2,'freq',freq(2),'U_inf',fs_vel,'U_inf_std',fs_std,'chord',chord,'span',span,'temperature',Temperature,'centerToWallTop',NaN,'centerToWallBot',NaN,'foil_geometry',foil_shape,'Delta_x',Delta_x2, 'Delta_y',Delta_y2,'data_location',data_location,'date_compiled',date,'nd_t',nd_t(1:10:end),'nd_lift',nd_lift(1:10:end,2),'nd_torque',nd_torque(1:10:end,2),'nd_heave_pos',nd_heave_pos2(1:10:end),'nd_heave_vel',nd_heave_vel(1:10:end,2),'run_date',run_date);
%     %NEED pitch_vel and down on list
    

    
    %% SAVE
%     save_name = strcat('flume_',num2str(round(heave(1)*100)),'Heave_',num2str(round(pitch(1))),'Pitch_',num2str(f_disp),'f_',num2str(absolute_phase1),'Phase_1.mat');
%     ii =1;
%     while exist([path_name save_name],'file')
%         ii = ii+1;
%         save_name = strcat('flume_',num2str(round(heave(1)*100)),'Heave_',num2str(round(pitch(1))),'Pitch_',num2str(f_disp),'f_',num2str(absolute_phase1),'Phase_',num2str(ii),'.mat');
%     end
%     save([path_name save_name],'foil');
    clear dat sub_dat out Torque Lift