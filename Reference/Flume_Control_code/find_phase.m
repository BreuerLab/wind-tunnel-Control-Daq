function phase1 = find_phase(t,y,f)
        [xData, yData] = prepareCurveData( t, y );

% Set up fittype and options.
ft = fittype( ['a*sin(2*pi*',num2str(f),'*x+phase*pi/180)'], 'independent', 'x', 'dependent', 'y' );
opts = fitoptions( 'Method', 'NonlinearLeastSquares' );
opts.Display = 'Off';
opts.Lower = [-Inf -360];
opts.Upper = [Inf 360];

opts.StartPoint = [1 -90];

% Fit model to data.
[fitresult, gof] = fit( xData, yData, ft, opts );
plot(fitresult, xData, yData );
phase1 = fitresult.phase;
