function plot_power(foil_struct)

N = numel(foil_struct.t_power_mean(:,1));
x = linspace(0,1,N);

plot(x,foil_struct.t_power_mean(:,1),x,foil_struct.heave_power_mean(:,1),x,foil_struct.pitch_power_mean(:,1))
legend('total','heave','pitch')
end
