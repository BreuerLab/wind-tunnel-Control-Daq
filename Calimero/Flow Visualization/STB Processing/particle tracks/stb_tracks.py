"""
stb_tracks.py - thin lvpyio wrapper meant to be called from MATLAB
(see loadSTBParticles.m in the same folder).

Everything returned is a plain float64 numpy array (or a dict of them), so
MATLAB can convert it with double(...). No structured arrays cross the bridge.

Written for 2-pulse Shake-the-Box particle fields (type DOUBLE_PULSE).
Particle fields are read with lvpyio.read_particles, which expects the path of
a DaVis particle set (the folder next to the .set file, no extension).
"""
import numpy as np
import lvpyio as lv

N_COLS = 9  # [x y z u v w I1 I2 track_id]

_open = {}  # cache of open particle fields, keyed by path


def _field(path):
    pf = _open.get(path)
    if pf is None or pf.closed:
        pf = lv.read_particles(path)
        _open[path] = pf
    return pf


def info(path):
    """Basic metadata: number of blocks, pulse type, scales, block times."""
    pf = _field(path)
    s = pf.scales
    t = np.asarray(pf.times(), dtype=np.float64)   # (n_blocks, 2) for 2-pulse
    return {
        "n_blocks": float(len(pf)),
        "pulses_per_block": float(pf.type_id.value),
        "track_count": float(pf.track_count),
        "times": t,
        "units": f"{s.x.unit},{s.y.unit},{s.z.unit}",
        "intensity_scale": np.array([s.i.slope, s.i.offset], dtype=np.float64),
    }


def _scaled(p, s):
    """Unscaled voxel coords -> physical units (usually mm)."""
    x = s.x.slope * p["x"].astype(np.float64) + s.x.offset
    y = s.y.slope * p["y"].astype(np.float64) + s.y.offset
    z = s.z.slope * p["z"].astype(np.float64) + s.z.offset
    return x, y, z


def read_block(path, block, vel_scale=1e-3):
    """
    One 2-pulse block -> N x 9 float64 matrix, one row per track:
        [x y z u v w I1 I2 track_id]
    x,y,z : midpoint of the two pulses (scaled units, e.g. mm)
    u,v,w : (pos2 - pos1)/dt * vel_scale   (mm/s * 1e-3 = m/s by default)
    I1,I2 : particle intensity in pulse 1 and pulse 2 (unscaled, raw DaVis units)
    block : 0-based block index
    """
    pf = _field(path)
    s = pf.scales
    blk = pf[int(block)]
    t = np.asarray(pf.times(), dtype=np.float64)[int(block)]
    dt = t[1] - t[0]

    a = blk[0].particles   # fields: track_id, particle(x,y,z,intensity)
    b = blk[1].particles
    if a.size == 0 or b.size == 0:
        return np.zeros((0, N_COLS))

    # pair pulse-1 and pulse-2 particles by track id
    ids, ia, ib = np.intersect1d(a["track_id"], b["track_id"],
                                 assume_unique=True, return_indices=True)
    pa = a["particle"][ia]
    pb = b["particle"][ib]

    x1, y1, z1 = _scaled(pa, s)
    x2, y2, z2 = _scaled(pb, s)

    out = np.empty((ids.size, N_COLS))
    out[:, 0] = 0.5 * (x1 + x2)
    out[:, 1] = 0.5 * (y1 + y2)
    out[:, 2] = 0.5 * (z1 + z2)
    out[:, 3] = (x2 - x1) / dt * vel_scale
    out[:, 4] = (y2 - y1) / dt * vel_scale
    out[:, 5] = (z2 - z1) / dt * vel_scale
    out[:, 6] = pa["intensity"].astype(np.float64)
    out[:, 7] = pb["intensity"].astype(np.float64)
    out[:, 8] = ids.astype(np.float64)
    return out


def read_blocks(path, blocks, vel_scale=1e-3):
    """
    Several blocks in one bridge call (fewer MATLAB<->Python round trips).
    Returns N x 10 matrix: [x y z u v w I1 I2 track_id block] (block 0-based).
    """
    parts = []
    for k in np.atleast_1d(np.asarray(blocks, dtype=np.int64)):
        m = read_block(path, k, vel_scale)
        parts.append(np.column_stack([m, np.full(len(m), float(k))]))
    return np.vstack(parts) if parts else np.zeros((0, N_COLS + 1))


def close(path=None):
    """Close one cached field, or all of them."""
    keys = [path] if path is not None else list(_open)
    for k in keys:
        pf = _open.pop(k, None)
        if pf is not None and not pf.closed:
            pf.close()
