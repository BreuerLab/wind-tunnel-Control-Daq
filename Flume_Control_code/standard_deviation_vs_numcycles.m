% Has the vectrino take varying numbers of readings at its current
% position, and then computes the standard deviation for each number of
% readings.
%
% Written by Max
% Edited by Walker

function STD = standard_deviation_vs_numcycles(start,finish)

for n = start:5:finish
   % Have the vectrino take n readings
   [flume,out,dat,Prof2,Prof_out] = run_cycle_3rigs_protocol_vect(0.7,0,0,0,0,70,0.75,0,0,n,95);
   pause (1);
   % Save data to file and repeat
   save(sprintf('standard_deviation_for_%d_cycles.mat',n));
end

STD = [0;0;0] ;
for jj = start:5:finish
    % Opens each file and computes standard deviations
    out = my_phaseaveraging('standard_deviation_for_jj_cycles.mat',100,0) ;
    stdxt = 0; stdyt = 0;  stdzt = 0; 
    for kk = 1:100 
        stdxt = stdxt + out(kk).sUx ;
        stdyt = stdyt + out(kk).sUy ;
        stdzt = stdzt + out(kk).sUz ;
    end 
    stdx = stdxt/100;
    stdy = stdyt/100 ;
    stdz = stdzt/100 ;
    % Puts the standard deviations into a single table for ease of analysis
    STD = horzcat(STD,[stdx;stdy;stdz]); 
end
 STD = STD' ; STD = STD(2:end,:);
 plot(STD); 
end

