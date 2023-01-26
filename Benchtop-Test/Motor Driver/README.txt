Author: Ronan Gissler
Date: November 2022

-------------------------------------------------------------------------------
Introduction
-------------------------------------------------------------------------------

This folder contains the necessary files to test a stepper motor using a Galil
DMC. In my case I'm using a Galil DMC 4143 with a PH266-E1.2 8-wire 2-phase
stepper motor from Oriental Motor. To describe this stepper motor in brief,
it's a DC electric motor that alternates between powering 2 coils called phases.
The magnetic field produced by these coils causes permanent magnets attached to
the shaft to move in small discrete steps. 

-------------------------------------------------------------------------------
Experimental Setup
-------------------------------------------------------------------------------
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
File Structure
-------------------------------------------------------------------------------

stepper_test.DMC
	A simple stepper motor test. Drives the stepper forward one revolution,
	pauses, and then drives the stepper backward one revolution.

-------------------------------------------------------------------------------
Debugging Tips
-------------------------------------------------------------------------------
Issue: Why is the stepper jittering rather than moving continuously?

Explanation: It's likely the stepper motor is not wired correctly to the DMC.
To verify your wiring arrangement, examine the wiring diagram in the user
manual of the datasheet for the Galil for your specific amplifier (Appendix 5
in my case). You can check which wires form a phase using the continuity setting
on the multimeter (wires forming a phase together should cause the multimeter to
beep when measuring continuity). If your wires seemed to be arranged correctly,
it's possible one of them is loose. Again, you continuity on a multimeter to 
evaluate connections.

Issue: Why is the stepper getting hot?

Explanation: The motor is drawing too much current. While holding any given
position, current will be flowing through one of the phases continuously rather
than off and on. Use the LC command to reduce the holding current to 25%. You
may also just be providing too much current in general, try adjusting the
amplifer using the AG and AU commands. Also consider heat transfer methods:
heat sink or forced air cooling. To check if you have burned out the motor,
measure the resistance of each phase with a multimeter. Very low resistance
indicates a shorted connection.

-------------------------------------------------------------------------------
Unresolved
-------------------------------------------------------------------------------
Why is not 3200 ticks for one revolution? Instead it is closer to 53000.
	It is actually 51200. Microsteps cannot be set for the AMP-43547
	amplifier on the Galil DMC 4143. Instead the microsteps per step
	is fixed at 256. 256*200 = 51200. Boy was that a pain to troubleshoot.

Why are the gears skipping? Are they not separated correctly?
	Yes, we've ordered a gearbox to correct this.