# Changes to make at the next full reprocess

Changes that rename or restructure saved variables, so they should go in
together with a full reprocess of the STB data rather than piecemeal. Remove
an item once it is done.

## Rename the Q centroid variables

The current names are misleading: `Qx_y` / `Qx_z` are the centroid weighted by
**Q**, and `Qxcomp_y` / `Qxcomp_z` are the centroid weighted by **Q_x**.

| Weighted by | Current name           | New name         |
|-------------|------------------------|------------------|
| Q           | `Qx_y`, `Qx_z`         | `Q_y`, `Q_z`     |
| Q_x         | `Qxcomp_y`, `Qxcomp_z` | `Qx_y`, `Qx_z`   |

Places to update:

- `processing functions/secondary statistics/calc_secondary_vals_common.m`
  (`S.Qx_y`, `S.Qx_z`, `S.Qxcomp_y`, `S.Qxcomp_z`)
- `STB UI/helper functions/get_Q_centroid.m` (accepted names)
- `STB UI/timeAvg_UI.m` (`var_names`, `is_live_Q_centroid`)
- `STB UI/phaseAvg_UI.m` (`flow_var_names`, the `live_qx` fallback)

Watch out: after the rename, `Qx_y` / `Qx_z` mean the Q_x centroid, but any
`_integral.mat` file not yet reprocessed still holds the Q centroid under those
names. The UIs would plot the wrong quantity from old files without saying so.
Either reprocess every case at once, or have the UIs tell old files from new
ones (e.g. check for `Q_y` in the file, or save a version tag) before reading
`Qx_y` / `Qx_z`.
