

newobjs = instrfind;
delete(newobjs);
clear all;

x_step = 5;
z_step = 1;

daq_setup_3rigs;

z_axis = serial('COM12','BaudRate',9600);
fopen(z_axis);
% fprintf(z_axis,'%s',char(0));

% move_traverse_walker(10);

for j=1:1:z_step

for i=1:1:x_step
    move_traverse_walker(10);% in mm, positive going away from user, negative going toward user
    pause(5)
    [flume,out,dat,Prof2,Prof_out]= run_cycle_3rigs_20181002;
    save(sprintf('x_step%d_z_step%d.mat',x_step,z_step),'out');
end

move_traverse_walker(-10*x_step);
pause(5);
fprintf(z_axis,'%s',char(1)); % 0 going down; 1 going up;
pause(5);

end