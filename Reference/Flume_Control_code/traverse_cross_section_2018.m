% clear obj -> daq_setup_3rigs -> run

newobjs = instrfind;
delete(newobjs);
clear all;
z_axis = serial('COM12','BaudRate',9600);

tic

for i = 1:5
fprintf(vect,'%s',char(1));
pause(1)
fprintf(vect,'%s',char(0));
end

toc



fopen(z_axis);

folder = 'C:\Users\ControlSystem\Documents\vertfoil\velocity_profile\';
% mkdir(date)

x_step = 15;
z_step = 1;

% x_step = 15;
% z_step = 1;

k = 0;
m = 0;

% daq_setup_3rigs_vel_profile_2018;
% daq_setup_3rigs;


% fprintf(z_axis,'%s',char(0));

% move_traverse_walker(10);

for j=0:1:z_step-1

for i=0:1:x_step
    if i==0
        
    [flume,out,dat,Prof2,Prof_out]= run_cycle_3rigs(1,0,0,0,0,0,0,0,0,15,0);
    cd([folder date]);
    save(sprintf('x_step%d_z_step%d.mat',i,j),'out');
    
    else
    move_traverse_walker(-30); m=m+1;% in mm, positive going away from user, negative going toward user
    pause(5)

    [flume,out,dat,Prof2,Prof_out]= run_cycle_3rigs(1,0,0,0,0,0,0,0,0,15,0);
    cd([folder date]);
    save(sprintf('x_step%d_z_step%d.mat',i,j),'out');
    
    end
%     [flume,out,dat,Prof2,Prof_out]= run_cycle_3rigs_20181002(1,0,0,0,0,65,1,0,0,10,90);

end

move_traverse_walker(30*x_step); m=0;
pause(10);
fprintf(z_axis,'%s',char(1));k=k+1;
fprintf(z_axis,'%s',char(1));k=k+1;
fprintf(z_axis,'%s',char(1));k=k+1;% 0 going down; 1 going up;
pause(30);

if j==z_step-1

for i=0:1:x_step
    if i==0
        
    [flume,out,dat,Prof2,Prof_out]= run_cycle_3rigs(1,0,0,0,0,0,0,0,0,15,0);
    cd([folder date]);
    save(sprintf('x_step%d_z_step%d.mat',i,j+1),'out');
    
    else
    move_traverse_walker(-30); m=m+1;% in mm, positive going away from user, negative going toward user
    pause(5)

    [flume,out,dat,Prof2,Prof_out]= run_cycle_3rigs(1,0,0,0,0,0,0,0,0,15,0);
    cd([folder date]);
    save(sprintf('x_step%d_z_step%d.mat',i,j+1),'out');
    
    end
%     [flume,out,dat,Prof2,Prof_out]= run_cycle_3rigs_20181002(1,0,0,0,0,65,1,0,0,10,90);

end

end

end