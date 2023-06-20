Author: Ronan Gissler
Date: June 2023

-------------------------------------------------------------------------------
Introduction
-------------------------------------------------------------------------------

This folder contains the necessary files to run a wind tunnel test using an ATI
force transducer to measure aerodynamic forces, a stepper motor to drive
the 1 DOF flapper robot, and the MPS servo motor to adjust the angle of attack
of the robot. To run the experiment simply activate the wind tunnel GUI and then
run the main.m file.

-------------------------------------------------------------------------------
Experimental Setup
-------------------------------------------------------------------------------
To use the force transducer you will need the following pieces of hardware
(Look at the image -> experimental_setup.jpg):
- force transducer
- amplifier box for the force transducer (and its power cord)
- cable to connect force transducer to amplifier
- cable to connect amplifier to NI-DAQ
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

-------------------------------------------------------------------------------
Procedure
-------------------------------------------------------------------------------

- Mount robot and force transducer on MPS arms
- Tuck carboard pieces into gap between MPS arms and wind tunnel floor
- Plug in force transducer to powered amplifier box
- Let sit in wind tunnel at desired wind speed at least until wind tunnel
  temperature equilibrates, ideally for several hours
- Connect Galil ethernet cable to PC and DAQ usb cable to PC
- Open Kollmorgen Workbench on wind tunnel computer and enable the pitching motor
- Turn on the wind tunnel and the chiller
- Open the wind tunnel GUI and confirm that live data is being plotted
- Open main.m, change parameters for specific trial, hit run

-------------------------------------------------------------------------------
File Structure
-------------------------------------------------------------------------------

NEEDS TO BE UPDATED...