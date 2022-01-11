fname = new_experiment;
% load('C:\Users\ControlSystem\Documents\vertfoil\Experiments\1foil\AoA_15-Jun-2017_10_5_37\Results.mat')

aoa = 20:5:60;
rf = 0.08:.02:.16;
h0 = 0.5:.25:1.25;
U = 0.485;
f = rf*U/.1;
for ii = 1:numel(rf)
    for jj = 6:numel(aoa)
        for kk = 1:numel(h0)
            [t,p,h] = single_cycle_aoa(rf(ii),aoa(jj),h0(kk)*.1,U);
            disp([rf(ii) aoa(jj) h0(kk)])
%             figure(1)
%             plot(t,p,t,h*100)
%             drawnow
            disp([max(p) max(h)])
            pause(.1)
%             figure(2)
            if max(p)>90
                
                etaaoa(ii,jj,kk,1) = NaN;
                etaaoa(ii,jj,kk,2) = NaN;
                paoa(ii,jj,kk) = NaN;
                haoa(ii,jj,kk) = NaN;
                freqaoa(ii,jj,kk) = NaN;
    %             figure(3)
%                 flume = run_cycle_3rigs(f(ii),0,0,0,0,paoa(ii,jj,kk),haoa(ii,jj,kk),0,0,10,90);

                eta(ii,jj,kk,1) = NaN;
                eta(ii,jj,kk,2) = NaN;
                p(ii,jj,kk) = NaN;
                h(ii,jj,kk) =NaN;
                freq(ii,jj,kk) = NaN;
            else
                disp('run')
            [flume] = run_cycle_3rigs_aoa(f(ii),aoa(jj),h0(kk),15,U);
            etaaoa(ii,jj,kk,1) = flume.foil3.eta_mean;
            etaaoa(ii,jj,kk,2) = flume.foil3.eta_std;
            paoa(ii,jj,kk) = max(flume.foil3.pitch_pos)*180/pi;
            haoa(ii,jj,kk) = max(flume.foil3.heave_pos)/2;
            freqaoa(ii,jj,kk) = flume.foil3.freq;
%             figure(3)
            flume = run_cycle_3rigs(f(ii),0,0,0,0,paoa(ii,jj,kk),haoa(ii,jj,kk),0,0,10,90);
            
            eta(ii,jj,kk,1) = flume.foil3.eta_mean;
            eta(ii,jj,kk,2) = flume.foil3.eta_std;
            p(ii,jj,kk) = max(flume.foil3.pitch_pos)*180/pi;
            h(ii,jj,kk) = max(flume.foil3.heave_pos)/2;
            freq(ii,jj,kk) = flume.foil3.freq;
            end
            
        end
    end
end
save([fname,'results.mat')