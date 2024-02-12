clear
close all

x = 0:0.01:1.01;
num_vals = length(x);
y = (1/2)*sin(2*pi*x);
y_neg_dist = (1 - x).*sin(2*pi*x);
y_pos_dist = x.*sin(2*pi*x);

figure
hold on
plot(x,y,DisplayName="Equilibrium",Linewidth=2)
plot(x,y_neg_dist,DisplayName="Response to Negative Disturbance",Linewidth=2)
plot(x,y_pos_dist,DisplayName="Response to Positive Disturbance",Linewidth=2)
xlim([0 1])
xlabel("Wingbeat Period (t / \tau)")
ylabel("Pitching Moment")
title("Potential Mechanism for Stability in Flapping Flight")
legend(Location="southwest")