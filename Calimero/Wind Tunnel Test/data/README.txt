There are 6 different types of data stored in this folder. Below I explain what
each folder contains and in what script (.m file) these data files were
produced.

-------------------------------------------------------------------------------

experiment data
	Added in: Calimero_parallel.m in the measure_force function. The
		  measure_force function is called by run_trial.m
	Contains: data files for each trial contains a matrix called 'results'
		  which contains the values for each variable (timestamp, 3
		  forces, 3 moments, voltage, current, motor position) as
		  time series

offsets data
	Added in: Calimero_parallel.m in the get_force_offsets function.
		  The get_force_offsets function is called by initial_tare.m
		  and run_trial.m
	Contains: data files for each tare measurement containing a matrix
		  with size 2 x 'number of variables'. The first row is
		  for mean values (the tare), while the second row is the
		  standard deviation of the measurement during the tare
		  period.

output logs
	Added in: run_experiment.m
	Contains: everything printed to the command window during the
		  experiment with a disp("") statement. Unclear if it
		  also logs warning and errors

plots
	Added in: run_experiment.m and raw_plot.m
	Contains: .fig file containing force/moment data vs. angle of attack
		  and .png files containing force/moment data and
		  voltage/curent/position data for each trial


wind tunnel data
	Added in: wind_tunnel_save.m
	Contains: AFAM_tunnel struct from AFAM GUI (wind speed, air temp, etc)
		  AND screenshots of the AFAM GUI (OUTDATED, DOESN'T WORK WHEN
		  CODE RUN ON PC OTHER THAN AFAM PC)

experiment_params
	Added in: run_experiment.m
	Contains: parameters related to all those experiments, things like the
	          DAQ sample rate