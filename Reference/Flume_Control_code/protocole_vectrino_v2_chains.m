

for kk = 1:4 
  for i = 0:(nb_step) 
  [flume,out,dat,Prof2,Prof_out] = run_cycle_3rigs_protocol_vect(.5,00,0,0,0,65,0.5,0,0,40,95);
  pause (1);
  if i == 1 
      save(sprintf('velocity_data_protocol_go_%d.mat',i));
  else 
      save(sprintf('velocity_data_protocol_back_%d.mat',i));
  end
  if i ~= nb_step
        move_traverse (meas_length/nb_step,0);  
  end
  
  end

end 
