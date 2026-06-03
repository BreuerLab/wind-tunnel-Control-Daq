Author: Ronan Gissler
Written on: June 02 2026

The codes here do the brunt of the processing work to convert vc7s to mat files
containing field quantities (e.g. velocity) and secondary statistics (e.g. lift
force).

-------------------------------------------------------------------------------
------------------------------ File Structure ---------------------------------
-------------------------------------------------------------------------------
import_STB_data.m ->
	Calls loadpiv, nondimensionalizes data, and then computes some
additional vector fields (vector totals and helicity). If the RPCA boolean is
activated this is where RPCA will take place.


phase_avg_STB.m ->
	Computes phase averaged results. If the proc_vel boolean is activated,
the velocity fields are phase averaged from scratch, otherwise only the
secondary statistics are calculated from the pre-existing mat file of velocity
fields.

time_avg_STB.m ->
	Computes time averaged results.

secondary statistics ->
	Functions for calculating secondary statistics called by phase_avg_STB.m
and time_avg_STB.m. Secondary statistics include aerodynamic forces, integral
quantities (e.g. kinetic energy, enstrophy, etc.), planar averages (e.g. average
u, average omega_x, etc.).

phase averaging helpers ->
	Functions used to obtain the bins used for phase averaging the velocity
fields and to compute phase average kinematics and power consumption with finer
phase resolution than the laser pulses.

general helpers ->
	Functions that perform a number of useful operations during processing
that serve both phase and time averaging.
