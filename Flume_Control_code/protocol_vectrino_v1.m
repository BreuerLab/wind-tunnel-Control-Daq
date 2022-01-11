function [complete_array_trino,velocity , STD] = protocol_vectrino_v1
% the vectrino should be placed in the y minimum of the range of
% measurement ( where y is at his minimum) 
% traverse should be initialized manually
% We still need to implement the moving of the Vector.

prompt = {'Enter measurement length (in mm): ','Enter desired number of steps (>=1):'};
name = 'Protocol Configuration';
num_lines = 1;
defaultanswer = {'0.0','1'};
answer = inputdlg(prompt,name,num_lines,defaultanswer);

meas_length = str2num(answer{1});
nb_step = str2num(answer{2});


% getting the data
for i = 0:(nb_step) 
  [flume,out,dat,Prof2,Prof_out] = run_cycle_3rigs_test(.7,00,0,0,0,0,0,0,0,10,0);
  A = flume; 
  A_trino = [A.foil3.Ux , A.foil3.Uy, A.foil3.Uz]; 
  if i == 0
     tempo_trino = A_trino;
         
  else 
     tempo_trino = horzcat(tempo_trino,A_trino);
     
  end
  
  if i ~= nb_step
           move_traverse (meas_length/nb_step,0); 
        pause(3);
 
  end
  
end
    complete_array_trino = tempo_trino;
  
    
%   nb_step = 60; 
%Processing data
% Averaged velocity
Velocity_mean_trino_tempo = mean(complete_array_trino);

for i = 1:(nb_step+1)
  if i == 1
        Ux_trino = Velocity_mean_trino_tempo (:,1); 
        Uy_trino = Velocity_mean_trino_tempo (:,2);
        Uz_trino = Velocity_mean_trino_tempo (:,3);
             
  else 
        Ux_trino = horzcat(Ux_trino, Velocity_mean_trino_tempo (:,3*(i-1) +1 )); 
        Uy_trino = horzcat(Uy_trino, Velocity_mean_trino_tempo (:,3*(i-1) +2 ));
        Uz_trino = horzcat(Uz_trino, Velocity_mean_trino_tempo (:,3*(i-1) +3 ));
  end
     
end
Velocity_mean_trino = [Ux_trino', Uy_trino', Uz_trino' ]; 
velocity = Velocity_mean_trino;

%Processing data
% Standard deviation of velocity

STD_trino_tempo = std(complete_array_trino);

for i = 1:(nb_step+1)
  if i == 1
         STDx_trino = STD_trino_tempo(:,1);
         STDy_trino = STD_trino_tempo (:,2);
         STDz_trino = STD_trino_tempo (:,3);
  else 
          STDx_trino = horzcat(STDx_trino, STD_trino_tempo (:,3*(i-1) +1 ));
          STDy_trino = horzcat(STDy_trino, STD_trino_tempo (:,3*(i-1) +2 ));
          STDz_trino = horzcat(STDz_trino, STD_trino_tempo (:,3*(i-1) +3 ));
  end
       
end
STD_trino = [STDx_trino', STDy_trino', STDz_trino' ]; 
STD = STD_trino;

end
    















% Velocity_mean_trino_tempo = mean(complete_array_trino);
% Velocity_mean_vec_tempo = mean(complete_array_vec); 
% 
% for i = 1:(nb_step)
%   if i == 1
%      Ux_trino = Velocity_mean_trino_tempo (:,1);
%      Uy_trino = Velocity_mean_trino_tempo (:,2);
%      Uz_trino = Velocity_mean_trino_tempo (:,3);
%      Ux_vec = Velocity_mean_vec_tempo (:,1);
%      Uy_vec = Velocity_mean_vec_tempo (:,2);
%      Uz_vec = Velocity_mean_vec_tempo (:,3);
%           
%   else 
%      Ux_trino = horzcat(Ux_trino, Velocity_mean_trino_tempo (:,3*(i-1) +1 ));
%      Uy_trino = horzcat(Uy_trino, Velocity_mean_trino_tempo (:,3*(i-1) +2 ));
%      Uz_trino = horzcat(Uz_trino, Velocity_mean_trino_tempo (:,3*(i-1) +3 ));
%      Ux_vec = horzcat(Ux_vec, Velocity_mean_vec_tempo (:,3*(i-1) +1 ));
%      Uy_vec = horzcat(Uy_vec, Velocity_mean_vec_tempo (:,3*(i-1) +2 ));
%      Uz_vec = horzcat(Uz_vec, Velocity_mean_vec_tempo (:,3*(i-1) +3 ));
%   end
%        
% end
% Velocity_mean_trino = [Ux_trino', Uy_trino', Uz_trino' ]; 
% Velocity_mean_vec = [Ux_vec', Uy_vec', Uz_vec' ]; 




% [flume,out,dat,Prof2,Prof_out] = run_cycle_3rigs(.5,00,0,0,0,40,1,0,0,10,90);
% A = flume; 
% A_trino = A.Vectrino ;
% 
% [flume,out,dat,Prof2,Prof_out] = run_cycle_3rigs(.5,00,0,0,0,40,1,0,0,10,90);
% B = flume; 
% B_trino = B.Vectrino ;
% 
% [n_trino,m_trino] = size(A_trino); tableau = zeros(n_trino,m_trino);tempo8 = horzcat(tableau,A_trino); tempo9 = horzcat(tempo8,B_trino);
