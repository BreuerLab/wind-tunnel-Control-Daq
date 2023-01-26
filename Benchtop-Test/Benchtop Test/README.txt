Author: Ronan Gissler
Date: December 2022

-------------------------------------------------------------------------------
Introduction
-------------------------------------------------------------------------------

This folder contains the necessary files to run a benchtop test using an ATI
force transducer to measure aerodynamic forces and a stepper motor to drive
the 1 DOF flapper robot. The main file here is benchtop_test.m.

-------------------------------------------------------------------------------
Experimental Setup
-------------------------------------------------------------------------------
To use the force transducer you will need the following pieces of hardware
(Look at the image -> experimental_setup.jpg):
- force transducer
- power supply for the force transducer (and its power cord)
- cable to connect force transducer to power supply
- cable to connect power supply to NI-DAQ
- NI-DAQ
- power cord for NI-DAQ
- USB connection from NI-DAQ to your computer

You will also need the following software:
- Matlab
- NI-DAQmx Support from Data Acquisition Matlab Toolbox
- NI Device Driver
- NI Max

To drive a stepper motor with the Galil DMC you will need the following
hardware:
- Galil DMC
- Stepper Motor (with 4 pin Molex connector to DMC)
- Power Supply (48V or 24V, check DMC specs)
- Wires to connect power supply to DMC
- Ethernet cable to connect DMC to your computer

You will also need the following software:
- Galil Design Kit
- Galil Tools and Galil ActiveX toolkit (to interface with Matlab)

If you'd like to just test the stepper motor or the force transducer, begin
instead with the code in the Motor Driver and Force Transducer folders.

-------------------------------------------------------------------------------
Procedure
-------------------------------------------------------------------------------

- Remove force transducer from case and let sit at room temperature for several 
  hours
- Mount interface plate on table
- Mount force transducer to interface plate and then robot to force transducer
- Plug in force transducer, DAQ, and DMC
- Connect DMC cable to PC and DAQ cable to PC
- Open benchtop_test.m, change parameters for specific trial, hit run

-------------------------------------------------------------------------------
File Structure
-------------------------------------------------------------------------------

12_02_2022_benchtop_test > 

	Data files from tests run on December 2nd 2022. For each test there
	are three files: the experiment results (first column is time, then
	Fx, Fy, Fz, Mx, My, Mz), the offset results (first row means, second
	row standard deviations), and then an image of the plot of the final
	results. Each test has a unique case name. For example
	"1Hz_100cycles_CBwing_2000acc" which means that for that test, a 
	wingbeat frequency of 1 Hz was prescribed, the wings beat 100 times,
	Carbon Black wings were used, and an acceleration value of 2000
	counts/sec^2 was used to bring the motors up to speed.

html >
	plot_data.pdf
		pdf of plot_data.m from the tests run on 12/02/2022
	filter_data.jpg
		plot from plot_data.m showing Carbon Black wing test results
		between 34 and 38 seconds after startup with a 6th order
		butterworth filter and a cutoff frequency of 3 significantly
		smoothing out the curves. Shows that the higher wingbeat
		frequencies are not as they were prescribed.
	raw_all_time_data.jpg
		plot from plot_data.m showing Carbon Black wing test results
		for all time and unfiltered. Shows that the higher wingbeat
		frequencies produced greater forces.

benchtop_test.m
	The file used to run the benchtop test. A number of parameters can
	be adjusted at the beginning of the file, most importantly the
	wingbeat speed.

benchtop_test_commented.dmc
	The dmc file whose placeholder acceleration and speed values are set
	by the user in benchtop_test.m. The dmc file is then uploaded to the
	Galil DMC to run the stepper motor and flap the wings.

ForceTransducer.m
	A Force Transducer class with methods get_force_offsets,
	measure_force, and plot_results which simplify the interface in
	benchtop_test.m.

plot_data.m
	Plots the experimental force transducer data from the .csv files and
	additional plots focusing on just the Carbon Black data. This is 
	how I reviewed the results from the tests to validate the
	experimental results in order to move onto wind tunnel tests.