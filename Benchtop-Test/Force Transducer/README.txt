Author: Ronan Gissler
Date: November 2022

-------------------------------------------------------------------------------
Introduction
-------------------------------------------------------------------------------

This folder contains the necessary files to test an ATI force transducer. In my
case I was using these files to test a new Gamma IP65 force transducer with a
NI USB-6341 DAQ. The main file here is force_transducer_test.m.

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

-------------------------------------------------------------------------------
File Structure
-------------------------------------------------------------------------------

11_3_2022 Test > 

	Data files from test run on November 3rd 2022. Look for descriptions
	below of files with the same name. The test run later in November
	limited the voltage range of the DAQ to +/- 5V in an attempt to improve
	the resolution of the digitization of the analog signal. This change
	did lead to improvements for larger masses, but seemed to be a detriment
	for smaller masses.

Calibration Files >
	FT43242 Calibration Certificate and Accuracy Report.pdf
		Information about 10V calibration. The 10V calibration allows
		the transducer to measure larger loads but at the expense of 
		lower resolution.

	FT43242.cal
		10V calibration matrix

	FT43243 Calibration Certificate and Accuracy Report.pdf
		Information about 5V calibration. The 5V calibration allows
		the transducer to measure with higher resolution but only
		for smaller loads.

	FT43243.cal
		5V calibration matrix


html >
	force_transducer_test_data.pdf
		pdf of plot_data.m from an experiment run in late November

0g_mass.xlsx
	Data from an experiment on the force transducer with no mass. The columns
	represent Fx, Fy, Fz, Mx, My, Mz, and time. The first row represents the
	mean values of the offsets for each axis, the second row represents the
	standard deviations of the offsets for each axis, and third row is a row
	of zeros to separate the offsets from the experiment data.

10g_mass.xlsx
	Data from an experiment on the force transducer with 10 grams. Data file
	packaged in the same way as described for 0g_mass.xlsx.

50g_mass.xlsx
	Data from an experiment on the force transducer with 50 grams. Data file
	packaged in the same way as described for 0g_mass.xlsx.

100g_mass.xlsx
	Data from an experiment on the force transducer with 100 grams. Data file
	packaged in the same way as described for 0g_mass.xlsx.

200g_mass.xlsx
	Data from an experiment on the force transducer with 200 grams. Data file
	packaged in the same way as described for 0g_mass.xlsx.

500g_mass.xlsx
	Data from an experiment on the force transducer with 500 grams. Data file
	packaged in the same way as described for 0g_mass.xlsx.

1000g_mass.xlsx
	Data from an experiment on the force transducer with 1000 grams. Data file
	packaged in the same way as described for 0g_mass.xlsx.

cal_FT43242_10V.mat
	10V calibration matrix in a .mat file rather than the provided .cal format

cal_FT43243_5V.mat
	5V calibration matrix in a .mat file rather than the provided .cal format

experimental_setup.jpg
	Picture of the complete setup required to test the force transducer

force_transducer_test.m
	Code to run a single force transducer test. Each xslx file was produced by
	running this file. 

obtain_cal.m
	Takes a calibration matrix in .cal format and makes one in the current
	working directory in a .mat format.

offsets.mat
	Before data is collected for each trial, offsets are collected and stored
	in this matrix. This is the same as zeroing a scale before measuring mass.

plot_data.m
	Plots the experimental force transducer data from the .xslx files and
	provides description statistics for each trial. This is how I reviewed
	the results from my force transducer tests to decide that it was working
	as expected.