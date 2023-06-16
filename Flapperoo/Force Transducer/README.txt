Author: Ronan Gissler
Date: November 2022

-------------------------------------------------------------------------------
Introduction
-------------------------------------------------------------------------------

This folder contains the necessary files to test an ATI force transducer. In my
case I was using these files to test a new Gamma IP65 force transducer with a
NI USB-6341 DAQ. The file to run here is force_transducer_test.m.

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

data >
	experiment data
		folder to store experiment data created by force_transducer_test.m
	offsets data
		folder to store taring data created by force_transducer_test.m
	plots
		folder to store plots created by force_transducer_test.m

force_transducer_test_data.pdf
	Some example data from a trial run in November 2022. Different brass pieces
	of known mass were placed on the force transducer.

experimental_setup.jpg
	Picture of the complete setup required to test the force transducer

force_transducer_test.m
	Code to run a single force transducer test. Data from the test is saved to the
	data folder.

ForceTransducer.m
	A Matlab class for the force transducer. This file is used in force_transducer_test.m
	to simplify the interface with the force transducer by making a force transducer
	object and calling its associated functions.