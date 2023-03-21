Author: Ronan Gissler
Date: December 2022

-------------------------------------------------------------------------------
Introduction
-------------------------------------------------------------------------------

This folder contains the necessary files to run a benchtop test using an ATI
force transducer to measure aerodynamic forces and a stepper motor to drive
the 1 DOF flapper robot. The main file here is benchtop_test.m.

THIS NEEDS TO BE UPDATED.....

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