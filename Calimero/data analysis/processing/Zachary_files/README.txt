This is the data processing unique to Zachary Rosoff's thesis (zjrosoff@gmail.com)

-- MAIN ANALYSES --

dimensionless_analysis.m generates the main results for the thesis

StRe_extract.m extracts the St and Re numbers from all trials (as long as they are grouped together)

StRe_plot.m generates histograms, error bars, and tables demonstrating the deviation in testing conditions (St and Re). Run after StRe_extract.m

-- ADDITIONAL ANALYSES --

avg_data_analysis.m generates the plots for the time-averaged data

body_subtraction_analysis.m generates the plots that demonstrate the body subtraction process

norm_data_analysis.m generates plots that demonstrate the nondimensionalizing process

raw_data_analysis.m generates plots that show the results of filtering and trimming the data

-- DATA --

LRS > group > Zachary > Thesis Data

plot_data_LE_fullShift
- dimensionless_analysis.m
- avg_data_analysis.m
- body_subtraction_analysis.m
- norm_data_analysis.m

wing_plot_LE_fullShift
- raw_data_analysis.m
- StRe_extract.m (I think)
- StRe_plot (after running StRe_extract.m)