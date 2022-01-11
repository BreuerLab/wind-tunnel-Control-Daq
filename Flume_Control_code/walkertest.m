% for ii = 10:3:34 
%    [flume,out,dat,Prof2,Prof_out] = run_cycle_3rigs_protocol_vect(0.7,0,0,0,0,70,75,0,0,ii,95);
%    pause (1);
%    save(sprintf('velocity_nbcyclesneeded_%d.mat',ii));
% end

STD = [0;0;0] ;
for jj = 10:100 
    out = my_phaseaveraging_v3('flume_3Rigs_75Heave_70Pitch_144f_2_100cycles.mat' , 100 ,0, jj)
    stdxt = 0; stdyt = 0;  stdzt = 0; 
    for kk = 1:100 
        stdxt = stdxt + out(kk).sUx ;
        stdyt = stdyt + out(kk).sUy ;
        stdzt = stdzt + out(kk).sUz ;
    end 
    
    stdx = stdxt/100;
    stdy = stdyt/100 ;
    stdz = stdzt/100 ;
    STD = horzcat(STD,[stdx;stdy;stdz]); 
   
end
 STD = STD' ; STD = STD(2:end,:);
 plot(STD); 