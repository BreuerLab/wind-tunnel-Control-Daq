clear
close all

t = 0:0.001:0.5;
f = 1;

A_vals = 0:0.01:(pi/2);
I_vals = zeros(size(A_vals));

for i = 1:length(A_vals)
    A = A_vals(i);
    y = cos(A*cos(2*pi*f*t));
    I_vals(i) = sum(y*0.001) / 0.5;
    % I_vals(i) = cumtrapz(t,y);
end

figure
hold on
plot(A_vals, cos(0.69*A_vals), LineWidth=2, DisplayName="Fit")
plot(A_vals, I_vals, LineWidth=2, DisplayName="Average")
xlabel("Amplitude $A$",Interpreter="latex")
ylabel("Average Value of $\cos\theta$ over one period",Interpreter="latex")
% legend()

%%
clear
t = 0:0.001:0.5;
f = 1;

A_vals = 0:0.01:(pi/2);
I_vals = zeros(size(A_vals));

for i = 1:length(A_vals)
    A = A_vals(i);
    y = cos(A*cos(2*pi*f*t)).*sin(2*pi*f*t);
    I_vals(i) = sum(y*0.001) / 0.5;
    % I_vals(i) = cumtrapz(t,y);
end

figure
hold on
% plot(A_vals, 0.6380*sin(0.5486*A_vals + 1.5949), LineWidth=2, DisplayName="Fit")
plot(A_vals, 0.64*cos(0.55*A_vals), LineWidth=2, DisplayName="Fit")
plot(A_vals, I_vals, LineWidth=2, DisplayName="Average")
legend()

%%
clear
t = 0:0.001:0.5;
f = 1;

A_vals = 0:0.01:(pi/2);
I_vals = zeros(size(A_vals));

for i = 1:length(A_vals)
    A = A_vals(i);
    y = cos(A*cos(2*pi*f*t)).*(sin(2*pi*f*t)).^3;
    I_vals(i) = sum(y*0.001) / 0.5;
    % I_vals(i) = cumtrapz(t,y);
end

figure
hold on
plot(A_vals, 0.43*cos(0.43*A_vals), LineWidth=2, DisplayName="Fit")
plot(A_vals, I_vals, LineWidth=2, DisplayName="Average")
legend()