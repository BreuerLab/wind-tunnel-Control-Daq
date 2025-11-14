function plot_current_comp(time, curAdj, TimeArr, Current, freq, padding_revs, time_to_speed, case_name)

startTimeDAQ = time_to_speed + padding_revs/freq;
trimmed_time = time(time > startTimeDAQ);
trimmed_curAdj = curAdj(time > startTimeDAQ);
trimmed_time = trimmed_time - min(trimmed_time);
endTime = 3/freq;
% current overlap plot
f_cur = figure;
hold on
plot(trimmed_time(time < endTime), trimmed_curAdj(time < endTime), Color=[0, 0.447, 0.741], DisplayName="INA169 Current")
scatter(trimmed_time(time < endTime), trimmed_curAdj(time < endTime), 10, [0, 0.447, 0.741], 'filled', HandleVisibility='off');
plot(TimeArr(TimeArr < endTime), Current(TimeArr < endTime), Color=[0.85, 0.325, 0.098], DisplayName="Galil Current")
scatter(TimeArr(TimeArr < endTime), Current(TimeArr < endTime), 10, [0.85, 0.325, 0.098], 'filled', HandleVisibility='off');
legend()
xlabel("Time (sec)")
ylabel("Current (mA)")
set(gca, FontSize=16)
saveas(f_cur,'data\plots\' + case_name + "_current_comp.png")

end