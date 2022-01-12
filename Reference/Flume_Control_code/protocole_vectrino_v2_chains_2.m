
clear;
nb_step = 45; meas_length = 600 ;
j = 0.4 ; k = 50 ; 

 

 for kk = 80:10:90
        for ii = 0:(nb_step) 
         [flume,out,dat,Prof2,Prof_out] = run_cycle_3rigs(j,00,0,0,0,kk,0.75,0,0,25,95); 
         pause (1);
         save(sprintf('velocity_mapping_freq_%d_pitch_%d_%d.mat',j, kk , ii));
         if i ~= nb_step
              move_traverse (meas_length/nb_step,0); 
         end
        end
        move_traverse (-meas_length,0); 
    end


        
        
for jj = 0.6:0.2:0.8  
     for kk = 50:10:90
        for ii = 0:(nb_step) 
         [flume,out,dat,Prof2,Prof_out] = run_cycle_3rigs(jj,00,0,0,0,kk,0.75,0,0,25,95); 
         pause (1);
         save(sprintf('velocity_mapping_freq_%d_pitch_%d_%d.mat',jj, kk , ii));
         if i ~= nb_step % Should the "i" here be "ii"? -Walker
              move_traverse (meas_length/nb_step,0); 
         end
        end
        move_traverse (-meas_length,0); 
    end
      
end