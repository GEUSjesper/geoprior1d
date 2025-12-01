import numpy as np

def flj_log():
    """
    flj_log(): Variant of jet colormap, designed by Flemming Jørgensen.
    Intended for log-scaled color axes: caxis([log10(0.1), log10(2600)])
    
    Returns:
        J (np.ndarray): Nx3 array of RGB values (float in [0,1])
    """
    x_c = np.array([
        0.1, 0.881, 1.93, 3.61, 6.79, 10, 14.7, 19.7, 25, 29.7, 35,
        39.7, 49.4, 60, 74.1, 90, 120, 150, 200, 247, 300, 400, 600, 1600, 2600
    ])
    lg_x_c = np.log10(x_c)
    d_lg_x_c = np.diff(lg_x_c) / 2
    m_lg_x_c = lg_x_c[:-1] + d_lg_x_c
    m_x_c = 10 ** m_lg_x_c

    c_m = np.array([
        [0, 0, 145],
        [0, 0, 180],
        [0, 50, 220],
        [0, 90, 245],
        [0, 140, 255],
        [0, 190, 255],
        [0, 220, 255],
        [1, 255, 255],
        [0, 255, 150],
        [0, 255, 1],
        [150, 255, 0],
        [210, 255, 0],
        [255, 255, 1],
        [255, 181, 0],
        [255, 115, 0],
        [255, 0, 1],
        [255, 28, 141],
        [255, 106, 255],
        [242, 0, 242],
        [202, 0, 202],
        [166, 0, 166],
        [128, 0, 128],
        [117, 0, 117],
        [100, 0, 117]
    ])
    
    # Normalize to [0,1]
    c_m_norm = (c_m + 1) / 256.0

    # Add boundaries
    m_x_c_t = np.concatenate(([x_c[0]], m_x_c, [x_c[-1]]))
    c_m_norm_t = np.vstack([c_m_norm[0], c_m_norm, c_m_norm[-1]])

    # Interpolation grid
    m_c_x_i = np.append(10 ** np.arange(-1, np.log10(2600), 0.01), 2600)
    
    # Interpolate each channel separately
    J = np.vstack([
        np.interp(m_c_x_i, m_x_c_t, c_m_norm_t[:, 0]),  # Red
        np.interp(m_c_x_i, m_x_c_t, c_m_norm_t[:, 1]),  # Green
        np.interp(m_c_x_i, m_x_c_t, c_m_norm_t[:, 2])   # Blue
    ]).T  # shape: (len(m_c_x_i), 3)
    
    # Clip to [0,1]
    J = np.clip(J, 0, 1)

    return J
