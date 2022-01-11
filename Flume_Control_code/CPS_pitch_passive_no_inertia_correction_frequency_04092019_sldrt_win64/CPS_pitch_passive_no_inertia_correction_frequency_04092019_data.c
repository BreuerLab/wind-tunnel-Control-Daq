/*
 * CPS_pitch_passive_no_inertia_correction_frequency_04092019_data.c
 *
 * Academic License - for use in teaching, academic research, and meeting
 * course requirements at degree granting institutions only.  Not for
 * government, commercial, or other organizational use.
 *
 * Code generation for model "CPS_pitch_passive_no_inertia_correction_frequency_04092019".
 *
 * Model version              : 1.233
 * Simulink Coder version : 8.12 (R2017a) 16-Feb-2017
 * C source code generated on : Tue Apr 09 22:09:33 2019
 *
 * Target selection: sldrt.tlc
 * Note: GRT includes extra infrastructure and instrumentation for prototyping
 * Embedded hardware selection: Intel->x86-64 (Windows64)
 * Code generation objectives: Unspecified
 * Validation result: Not run
 */

#include "CPS_pitch_passive_no_inertia_correction_frequency_04092019.h"
#include "CPS_pitch_passive_no_inertia_correction_frequency_04092019_private.h"

/* Block parameters (auto storage) */
P_CPS_pitch_passive_no_inertia_correction_frequency_04092019_T
  CPS_pitch_passive_no_inertia_correction_frequency_04092019_P = {
  0.0097500000000000017,               /* Variable: Bv
                                        * Referenced by: '<Root>/virtual damping1'
                                        */
  0.159,                               /* Variable: Ip
                                        * Referenced by: '<Root>/inverse  Inertia'
                                        */
  0.48,                                /* Variable: Kv
                                        * Referenced by: '<Root>/virtual stiffness1'
                                        */

  /*  Variable: Wallace_Cal_tranp
   * Referenced by: '<Root>/conversion  matrix'
   */
  { -1.7197, 0.1104, 1.46025, -69.84038, 3.68516, 68.11122, 0.51394, 84.16248,
    -3.36146, -40.0452, 1.85967, -39.49239, 117.99928, 1.50747, 120.04071,
    1.86535, 118.63511, 2.37547, -0.00699, 1.93336, -4.19985, -0.99298, 4.13985,
    -0.81273, 4.77798, 0.06742, -2.40357, 1.56279, -2.45998, -1.61599, -0.02305,
    -2.79011, 0.07486, -2.66323, -0.16141, -2.59783 },
  10.0,                                /* Mask Parameter: AnalogInput1_MaxMissedTicks
                                        * Referenced by: '<Root>/Analog Input1'
                                        */
  10.0,                                /* Mask Parameter: AnalogInput2_MaxMissedTicks
                                        * Referenced by: '<Root>/Analog Input2'
                                        */
  10.0,                                /* Mask Parameter: AnalogOutput_MaxMissedTicks
                                        * Referenced by: '<Root>/Analog Output'
                                        */
  10.0,                                /* Mask Parameter: AnalogOutput1_MaxMissedTicks
                                        * Referenced by: '<Root>/Analog Output1'
                                        */
  0.0,                                 /* Mask Parameter: AnalogInput1_YieldWhenWaiting
                                        * Referenced by: '<Root>/Analog Input1'
                                        */
  0.0,                                 /* Mask Parameter: AnalogInput2_YieldWhenWaiting
                                        * Referenced by: '<Root>/Analog Input2'
                                        */
  0.0,                                 /* Mask Parameter: AnalogOutput_YieldWhenWaiting
                                        * Referenced by: '<Root>/Analog Output'
                                        */
  0.0,                                 /* Mask Parameter: AnalogOutput1_YieldWhenWaiting
                                        * Referenced by: '<Root>/Analog Output1'
                                        */

  /*  Mask Parameter: AnalogInput1_Channels
   * Referenced by: '<Root>/Analog Input1'
   */
  { 0, 1, 2, 3, 4, 5, 22, 23 },

  /*  Mask Parameter: AnalogInput2_Channels
   * Referenced by: '<Root>/Analog Input2'
   */
  { 6, 7, 8, 9 },
  0,                                   /* Mask Parameter: AnalogOutput_Channels
                                        * Referenced by: '<Root>/Analog Output'
                                        */
  1,                                   /* Mask Parameter: AnalogOutput1_Channels
                                        * Referenced by: '<Root>/Analog Output1'
                                        */
  0,                                   /* Mask Parameter: AnalogInput1_RangeMode
                                        * Referenced by: '<Root>/Analog Input1'
                                        */
  0,                                   /* Mask Parameter: AnalogInput2_RangeMode
                                        * Referenced by: '<Root>/Analog Input2'
                                        */
  0,                                   /* Mask Parameter: AnalogOutput_RangeMode
                                        * Referenced by: '<Root>/Analog Output'
                                        */
  0,                                   /* Mask Parameter: AnalogOutput1_RangeMode
                                        * Referenced by: '<Root>/Analog Output1'
                                        */
  0,                                   /* Mask Parameter: AnalogInput1_VoltRange
                                        * Referenced by: '<Root>/Analog Input1'
                                        */
  0,                                   /* Mask Parameter: AnalogInput2_VoltRange
                                        * Referenced by: '<Root>/Analog Input2'
                                        */
  0,                                   /* Mask Parameter: AnalogOutput_VoltRange
                                        * Referenced by: '<Root>/Analog Output'
                                        */
  0,                                   /* Mask Parameter: AnalogOutput1_VoltRange
                                        * Referenced by: '<Root>/Analog Output1'
                                        */
  0.017453292519943295,                /* Expression: 1/180*pi
                                        * Referenced by: '<Root>/to rad'
                                        */
  0.0,                                 /* Expression: 0
                                        * Referenced by: '<Root>/offset(deg)'
                                        */

  /*  Expression: -tare.signals.values(end,:)
   * Referenced by: '<Root>/force bias'
   */
  { 0.61605872383165672, 0.77784004282365415, 0.39365926728334072,
    0.18695398607775568, 0.056698493317728658, 0.096441422294631554 },
  0.0,                                 /* Expression: 0
                                        * Referenced by: '<Root>/Unit  Delay1'
                                        */
  0.00025,                             /* Computed Parameter: Integrator1_gainval
                                        * Referenced by: '<Root>/Integrator1'
                                        */
  0.0,                                 /* Expression: 0
                                        * Referenced by: '<Root>/Integrator1'
                                        */
  0.00025,                             /* Computed Parameter: Integrator1_gainval_j
                                        * Referenced by: '<Root>/Integrator 1'
                                        */
  0.0,                                 /* Expression: 0
                                        * Referenced by: '<Root>/Integrator 1'
                                        */
  0.0,                                 /* Expression: 0
                                        * Referenced by: '<Root>/Constant2'
                                        */
  -3.3953054526271012,                 /* Expression: -5.*10/30000*12800/360*1.00*180/pi
                                        * Referenced by: '<Root>/angle out deg'
                                        */
  -33.333333333333336,                 /* Expression: -1/0.03
                                        * Referenced by: '<Root>/position out  (Voltage)'
                                        */
  -0.2610966057441253,                 /* Expression: -1/3.83
                                        * Referenced by: '<Root>/conversion2'
                                        */
  1.0,                                 /* Expression: 1
                                        * Referenced by: '<Root>/target pitch out(rad)'
                                        */
  0.0,                                 /* Expression: 0
                                        * Referenced by: '<Root>/virtual mass1'
                                        */
  -2.5,                                /* Expression: -2.5
                                        * Referenced by: '<Root>/Bias'
                                        */
  0.4,                                 /* Expression: 0.4
                                        * Referenced by: '<Root>/conversion1'
                                        */
  1U                                   /* Computed Parameter: zero1_CurrentSetting
                                        * Referenced by: '<Root>/zero1'
                                        */
};
