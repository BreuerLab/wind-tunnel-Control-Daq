If you ever want to quickly adjust the pitch angle of the MPS from the
command window, simple type move_pitch(true, DESIRED_ANGLE). "true" allows
the MPS to be enabled via the code rather than manually by the user. 
move_pitch.m is stored in the 'experiment functions' folder

----------------------------------------------------------------------------
----------------------------- File structure -------------------------------
----------------------------------------------------------------------------

main.m
	This is the file to run in order to run a wind tunnel experiment. All one
	has to do is enter the parameters over which they wish to test and then
	hit run.

run_experiment.m
	This file is called by main.m and handles all the details of actually
	running the experiment. It's main structure is composed of a nested
	while-loop within a while-loop. This loops through all angles of attack
	and wingbeat frequencies selected by the user.

run_trial.m
	This file is called for each iteration of the nested loop inside
	run_experiment.m and executes the basic actions of collecting data
	for each combination of test parameters.