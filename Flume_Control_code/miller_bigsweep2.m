redfreq = 0.075:0.025:0.175;%5
pitch = 50:10:90;%8
heave = 0.25:.25:1.5;%6
phase = 80:10:110;%4

U = 0.4673;
freq = redfreq*U/0.1;
% nn = 1;
% params = [];
for ii = 3:numel(pitch)
    for jj = 1:numel(heave)
        for kk = 1:numel(freq)
            for mm = 1:numel(phase)
                disp([ii jj kk,mm])
                [flume] = run_cycle_3rigs(freq(kk),0,0,0,0,pitch(ii),heave(jj),0,0,10,phase(mm));
                
                freqmat(ii,jj,kk,mm) = freq(kk);
                pitchmat(ii,jj,kk,mm) = pitch(ii);
                heavemat(ii,jj,kk,mm) = heave(jj);
                phasemat(ii,jj,kk,mm) = phase(mm);
                eta(ii,jj,kk,mm) = flume.foil3.eta_mean;
                etastd(ii,jj,kk,mm) = flume.foil3.eta_std;
                
                params(nn,1:6) = [freq(kk) pitch(ii) heave(jj) phase(mm) flume.foil3.eta_mean flume.foil3.eta_std];
                disp(params)
                nn = nn+1;
            end
            
            
        end
        

          
        
    end
            disp('stop flume, hit enter to bias FT')
        msgbox('Stop the flume')
        save(['C:\Users\ControlSystem\Documents\vertfoil\Experiments\1foil\bigsweep1_15-Sep-2017_10_30_56\results',num2str(nn)],'freqmat','pitchmat','heavemat','phasemat','eta','etastd','params')
        beep
        pause(.5)
        beep
        pause(.5)
        beep    
        pause(.5)
        beep
        pause

        find_bias_3rigs;
        beep
        disp('run flume. press any key twice find zero pitch and to start again')
        pause
          pause
          find_zero_pitch;
          beep
end

          