
%1/15/2016 rough single foil parameter sweep
heave = [0,.25,.5,.75,1,1.25,1.5];
pitch = [50,60,70,80];
red_freq = .06:.02:.2;
    flume_vel = run_cycle_3rigs(1,0,0,0,0,0,0,0,0,10);
    U_inf = flume_vel.foil3.U_inf;
freq = red_freq*U_inf/.1;
phi = 90;
run_num = 0;

for ii = 1:numel(freq)
    for jj = 1:numel(pitch)
        for kk = 1:numel(heave)
            
            for ll = 1:numel(phi)
            run_num = run_num+1;
                flume = run_cycle_3rigs(freq(ii),0,0,0,0,pitch(jj),heave(kk),0,0,10);
            sweep_results(run_num,:) = [red_freq(ii) pitch(jj) heave(kk) flume.foil3.eta_mean flume.foil3.eta_std];
            disp([red_freq(ii) pitch(jj) heave(kk) flume.foil3.eta_mean flume.foil3.eta_std])
        if abs(flume.out(1,3)-flume.out(end,3))*180/pi>1
            
            disp('Pitch is off. Press any key to zero pitch.')
            pause
            find_zero_pitch_3rigs;
        end
            clear flume
%             find_zero_pitch_3rigs;
            end
        end
        

    end
%         find_bias_3rigs;
%         find_zero_pitch_3rigs;
%         disp('run flume again. press any key to continue.')
%         pause
end