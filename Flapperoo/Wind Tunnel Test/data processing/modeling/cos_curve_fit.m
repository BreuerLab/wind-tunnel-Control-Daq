% fits a curve to the data of the form:
% y = B*cos(w*x) + C
% B, C are solved for using linear regression
% Assumption: xvals and yvals have the same size
function [w, B, C] = cos_curve_fit(x_vals, y_vals)

w_vals = 10:0.01:20;
lowest_err = -1;

for j = 1:length(w_vals)
w_cur = w_vals(j);
% allocate empty arrays on which to construct sums
coeff_mat = zeros(2,2);
y_mat = zeros(2,1);
for i = 1:length(x_vals)
    coeff_mat(1,1) = coeff_mat(1,1) + (cosd(w_cur*x_vals(i)))^2;

    coeff_mat(1,2) = coeff_mat(1,2) + cosd(w_cur*x_vals(i));

    coeff_mat(2,1) = coeff_mat(2,1) + cosd(w_cur*x_vals(i));

    coeff_mat(2,2) = coeff_mat(2,2) + 1;

    y_mat(1) = y_mat(1) + y_vals(i) * cosd(w_cur*x_vals(i));

    y_mat(2) = y_mat(2) + y_vals(i);
end

% calculate the coefficients B, C
coeffs = coeff_mat \ y_mat;
B_temp = coeffs(1);
C_temp = coeffs(2);

% evaluate the error associated with this fit
err_sum = 0;
model = B_temp*cosd(w_cur*x_vals) + C_temp;

for i = 1:length(x_vals)
    err_sum = err_sum + abs(y_vals(i) - model(i));
end
avg_err = err_sum / length(x_vals);
if (avg_err < lowest_err || j==1)
    lowest_err = avg_err;
    B = B_temp;
    C = C_temp;
    w = w_cur;
end

end

end

% % fits a curve to the data of the form:
% % y = B*sin(w*x) + C
% % B, C are solved for using linear regression
% % Assumption: xvals and yvals have the same size
% function [w, B, C] = sin_curve_fit(x_vals, y_vals)
% 
% w_vals = 10:0.01:20;
% lowest_err = -1;
% 
% for j = 1:length(w_vals)
% w_cur = w_vals(j);
% % allocate empty arrays on which to construct sums
% coeff_mat = zeros(2,2);
% y_mat = zeros(2,1);
% for i = 1:length(x_vals)
%     coeff_mat(1,1) = coeff_mat(1,1) + (sind(w_cur*x_vals(i)))^2;
% 
%     coeff_mat(1,2) = coeff_mat(1,2) + sind(w_cur*x_vals(i));
% 
%     coeff_mat(2,1) = coeff_mat(2,1) + sind(w_cur*x_vals(i));
% 
%     coeff_mat(2,2) = coeff_mat(2,2) + 1;
% 
%     y_mat(1) = y_mat(1) + y_vals(i) * sind(w_cur*x_vals(i));
% 
%     y_mat(2) = y_mat(2) + y_vals(i);
% end
% 
% % calculate the coefficients B, C
% coeffs = coeff_mat \ y_mat;
% B_temp = coeffs(1);
% C_temp = coeffs(2);
% 
% % evaluate the error associated with this fit
% err_sum = 0;
% model = B_temp*sind(w_cur*x_vals) + C_temp;
% 
% for i = 1:length(x_vals)
%     err_sum = err_sum + abs(y_vals(i) - model(i));
% end
% avg_err = err_sum / length(x_vals);
% if (avg_err < lowest_err || j==1)
%     lowest_err = avg_err;
%     B = B_temp;
%     C = C_temp;
%     w = w_cur;
% end
% 
% end
% 
% end

% % fits a curve to the data of the form:
% % y = B*sin(w*x + off) + C
% % B, C are solved for using linear regression
% % Assumption: xvals and yvals have the same size
% function [off, w, B, C] = sin_curve_fit(x_vals, y_vals, iter)
% if(iter > 1)
% [off, w, B, C] = sin_curve_fit(x_vals, y_vals, iter - 1);
% else
%     off = 0;
% end
% 
% w_vals = 10:0.01:30;
% lowest_err = -1;
% 
% for j = 1:length(w_vals)
% w_cur = w_vals(j);
% % allocate empty arrays on which to construct sums
% coeff_mat = zeros(2,2);
% y_mat = zeros(2,1);
% for i = 1:length(x_vals)
%     coeff_mat(1,1) = coeff_mat(1,1) + (sind(w_cur*x_vals(i) + off))^2;
% 
%     coeff_mat(1,2) = coeff_mat(1,2) + sind(w_cur*x_vals(i) + off);
% 
%     coeff_mat(2,1) = coeff_mat(2,1) + sind(w_cur*x_vals(i) + off);
% 
%     coeff_mat(2,2) = coeff_mat(2,2) + 1;
% 
%     y_mat(1) = y_mat(1) + y_vals(i) * sind(w_cur*x_vals(i) + off);
% 
%     y_mat(2) = y_mat(2) + y_vals(i);
% end
% 
% % calculate the coefficients B, C
% coeffs = coeff_mat \ y_mat;
% B_temp = coeffs(1);
% C_temp = coeffs(2);
% 
% % evaluate the error associated with this fit
% err_sum = 0;
% model = B_temp*sind(w_cur*x_vals + off) + C_temp;
% 
% for i = 1:length(x_vals)
%     err_sum = err_sum + abs(y_vals(i) - model(i));
% end
% avg_err = err_sum / length(x_vals);
% if (avg_err < lowest_err || j==1)
%     lowest_err = avg_err;
%     B = B_temp;
%     C = C_temp;
%     w = w_cur;
% end
% 
% end
% 
% off_vals = -80:0.01:80;
% 
% for j = 1:length(off_vals)
% off_cur = off_vals(j);
% % allocate empty arrays on which to construct sums
% coeff_mat = zeros(2,2);
% y_mat = zeros(2,1);
% for i = 1:length(x_vals)
%     coeff_mat(1,1) = coeff_mat(1,1) + (sind(w*x_vals(i) + off_cur))^2;
% 
%     coeff_mat(1,2) = coeff_mat(1,2) + sind(w*x_vals(i) + off_cur);
% 
%     coeff_mat(2,1) = coeff_mat(2,1) + sind(w*x_vals(i) + off_cur);
% 
%     coeff_mat(2,2) = coeff_mat(2,2) + 1;
% 
%     y_mat(1) = y_mat(1) + y_vals(i) * sind(w*x_vals(i) + off_cur);
% 
%     y_mat(2) = y_mat(2) + y_vals(i);
% end
% 
% % calculate the coefficients B, C
% coeffs = coeff_mat \ y_mat;
% B_temp = coeffs(1);
% C_temp = coeffs(2);
% 
% % evaluate the error associated with this fit
% err_sum = 0;
% model = B_temp*sind(w*x_vals + off_cur) + C_temp;
% 
% for i = 1:length(x_vals)
%     err_sum = err_sum + abs(y_vals(i) - model(i));
% end
% avg_err = err_sum / length(x_vals);
% if (avg_err < lowest_err || j==1)
%     lowest_err = avg_err;
%     B = B_temp;
%     C = C_temp;
%     off = off_cur;
% end
% 
% end
% 
% disp("y = " + B + "sin(" + w +"*x + " + off + ") + " + C)
% end