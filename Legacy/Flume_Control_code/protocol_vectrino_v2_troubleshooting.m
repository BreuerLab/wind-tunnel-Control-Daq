nb_step = 30 ; meas_length = 150;

% Varying Frequency 
for i = 0:(nb_step) 
  [flume,out,dat,Prof2,Prof_out] = run_cycle_3rigs_protocol_vect(.35,00,0,0,0,70,0.75,0,0,10,95);
  pause (1);
  save(sprintf('velocity_frequency_035_%d.mat',i));
   
  if i ~= nb_step
        move_traverse (meas_length/nb_step,0);  
  end
  
end
move_traverse(-150,0);
for i = 0:(nb_step) 
  [flume,out,dat,Prof2,Prof_out] = run_cycle_3rigs_protocol_vect(.525,00,0,0,0,70,0.75,0,0,10,95);
  pause (1);
  save(sprintf('velocity_frequency_0525_%d.mat',i));
   
  if i ~= nb_step
        move_traverse (meas_length/nb_step,0);  
  end
  
end
move_traverse(-150,0);




% Varying Pitch
for i = 0:(nb_step) 
  [flume,out,dat,Prof2,Prof_out] = run_cycle_3rigs_protocol_vect(.7,00,0,0,0,35,0.75,0,0,10,95);
  pause (1);
  save(sprintf('velocity_pitch_35_%d.mat',i));
   
  if i ~= nb_step
        move_traverse (meas_length/nb_step,0);  
  end
  
end
move_traverse(-150,0);

for i = 0:(nb_step) 
  [flume,out,dat,Prof2,Prof_out] = run_cycle_3rigs_protocol_vect(.7,00,0,0,0,52.5,0.75,0,0,10,95);
  pause (1);
  save(sprintf('velocity_pitch_525_%d.mat',i));
   
  if i ~= nb_step
        move_traverse (meas_length/nb_step,0);  
  end
  
end
move_traverse(-150,0);




% Varying Heave
for i = 0:(nb_step) 
  [flume,out,dat,Prof2,Prof_out] = run_cycle_3rigs_protocol_vect(.7,00,0,0,0,70,0.25,0,0,10,95);
  pause (1);
  save(sprintf('velocity_heave_25_%d.mat',i));
   
  if i ~= nb_step
        move_traverse (meas_length/nb_step,0);  
  end
  
end
move_traverse(-150,0);

for i = 0:(nb_step) 
  [flume,out,dat,Prof2,Prof_out] = run_cycle_3rigs_protocol_vect(.7,00,0,0,0,70,0.50,0,0,10,95);
  pause (1);
  save(sprintf('velocity_heave_50_%d.mat',i));
   
  if i ~= nb_step
        move_traverse (meas_length/nb_step,0);  
  end
  
end
move_traverse(-150,0);





% Varying Cycles
for i = 0:(nb_step) 
  [flume,out,dat,Prof2,Prof_out] = run_cycle_3rigs_protocol_vect(.7,00,0,0,0,70,0.75,0,0,20,95);
  pause (1);
  save(sprintf('velocity_cycles_20_%d.mat',i));
   
  if i ~= nb_step
        move_traverse (meas_length/nb_step,0);  
  end
  
end
move_traverse(-150,0);

for i = 0:(nb_step) 
  [flume,out,dat,Prof2,Prof_out] = run_cycle_3rigs_protocol_vect(.7,00,0,0,0,70,0.75,0,0,30,95);
  pause (1);
  save(sprintf('velocity_cycles_30_%d.mat',i));
   
  if i ~= nb_step
        move_traverse (meas_length/nb_step,0);  
  end
  
end
move_traverse(-150,0);
