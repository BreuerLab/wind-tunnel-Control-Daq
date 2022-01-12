for ii = 1:10
    run_optimization_foreground;
    find_zero_pitch;
end
%% load results, investigate efficiency drift

folders = dir('C:\Users\ControlSystem\Documents\vertfoil\Experiments\1foil\4D_optimization_0*Sep*')


for ii = 3:numel(folders)
    load(['C:\Users\ControlSystem\Documents\vertfoil\Experiments\1foil\',folders(ii).name,'\results.mat']);
    
    results4d(1:numel(exp_results(:,1)),1:8,ii-2) = exp_results;
    numel(exp_results(:,1))
end


[x,ind] = sort(results4d(:,7,:),1);

for ii = 1:10
    load(['C:\Users\ControlSystem\Documents\vertfoil\Experiments\1foil\',folders(ii+2).name,'\data\flume_3Rigs_75Heave_55Pitch_105f_1.mat']);
    
%     res(ii).exp_results = flume.foil3;
    
%     plot(medfilt1(flume.foil3.lift_N,20))
%     hold on
    lift(ii) = mean(abs(flume.foil3.lift_N));
    eta(ii) = flume.foil3.eta_mean;
end
hold off


%%
for ii = 1:5
    subplot(2,3,ii)
plot(squeeze(results4d(:,ii+2,:)),'.')
end