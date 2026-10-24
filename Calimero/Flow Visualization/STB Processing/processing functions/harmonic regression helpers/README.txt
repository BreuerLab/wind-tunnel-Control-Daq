Author: Ronan Gissler
Written on: October 24 2026

Harmonic regression, the alternative to bin averaging in phase_avg_STB.m
(bools.harmonic_reg = true in main_processing.m). Every point's time series
is fitted, by least squares over all frames at their actual phases, with
a Fourier series of H wingbeat harmonics. The fit is evaluated at the bin
centres, so the saved *_phase_avg fields have the same shape as before.

The fit is done in a streaming way: as phase_avg_STB loads each bin, its
frames are added to running sums (K = 2H+1 per point and field) and then
discarded. Frames with NaN (holes) are left out of each point's fit.

-------------------------------------------------------------------------------
------------------------------ File Structure ---------------------------------
-------------------------------------------------------------------------------
harmonic_regression_STB.m (in processing functions/) ->
	Top-level function called by phase_avg_STB: combines the sums, solves
for the coefficients, evaluates the fitted fields at the requested phases and
fits the per-frame forces.

harmonic_basis.m ->
	Fourier basis [1, cos, sin, ...] in phase (cycles), or its derivatives.

hr_accumulate.m ->
	Adds a chunk of frames to the running sums, including the corrections
for frames missing (NaN) at a point.

hr_merge.m ->
	Combines the sums from several parallel workers.

hr_solve.m ->
	Solves for the coefficients at every point. Points with too few valid
frames, or whose valid frames don't cover the cycle, are left NaN.

hr_fit_scalar.m ->
	Harmonic regression of one per-frame series (e.g. lift on each frame).

harmonic_eval.m ->
	Evaluates saved coefficients (bools.hr_save_coef) at any phase, or their
exact time derivative, e.g. harmonic_eval(S.u_hr_coef, phi, 1, S.hr.freq).
