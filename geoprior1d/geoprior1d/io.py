import pandas as pd
import numpy as np

def extract_prior_info(filename):
    """
    Reads geological prior information from an Excel file.

    Args:
        filename (str): Path to Excel file.

    Returns:
        info (dict): Structured information from the Excel sheets.
        cmaps (dict): RGB color mapping for geological classes.
    """
    info = {}
    cmaps = {}

    # Read tables
    T_geo1 = pd.read_excel(filename, sheet_name='Geology1')
    T_geo2 = pd.read_excel(filename, sheet_name='Geology2')
    T_res = pd.read_excel(filename, sheet_name='Resistivity')

    # Classes
    info['Classes'] = {
        'names': T_geo1['Class'].tolist(),
        'min_thick': T_geo1['Min thickness'].astype(float).to_numpy(),
        'max_thick': T_geo1['Max thickness'].astype(float).to_numpy(),
        'codes': list(range(1, len(T_geo1['Class']) + 1))
    }

    # Colormap from RGB strings (e.g. "255,0,0")
    rgb_raw = T_geo1['RGB color'].astype(str)
    cmaps['Classes'] = np.array([
        np.fromstring(rgb_str, sep=',') / 255.0 for rgb_str in rgb_raw
    ])

    # Sections
    info['Sections'] = {
        'N_sections': len(T_geo2),
        'types': [list(map(int, s.split(','))) for s in T_geo2['Classes']],
        'probabilities': [list(map(float, str(s).split(','))) for s in T_geo2['Probabilities']],
        'min_layers': T_geo2['Min no of layers'].astype(float).to_numpy(),
        'max_layers': T_geo2['Max no of layers'].astype(float).to_numpy(),
        'min_thick': T_geo2['Min unit thickness'].astype(float).to_numpy(),
        'max_thick': T_geo2['Max unit thickness'].astype(float).to_numpy(),
        'frequency': T_geo2['Frequency'].astype(float).to_numpy(),
        'repeat': T_geo2['Repeat'].astype(float).to_numpy(),
        'min_depth': T_geo2['Min depth'].astype(float).to_numpy(),
    }

    # Normalize probabilities: convert "1" to uniform distribution (preprocessing)
    for i in range(len(info['Sections']['probabilities'])):
        if info['Sections']['probabilities'][i][0] == 1:
            n_types = len(info['Sections']['types'][i])
            info['Sections']['probabilities'][i] = (np.ones(n_types) / n_types).tolist()

    # Resistivity
    res = T_res['Resistivity'].astype(float).to_numpy()
    res_unc = T_res['Resistivity uncertainty'].astype(float).to_numpy()
    info['Resistivity'] = {
        'res': res,
        'res_unc': np.log10(res_unc) / 3
    }

    # Try to load unsaturated resistivity (newer format)
    try:
        unsat_res = T_res['Unsaturated resistivity'].astype(float).to_numpy()
        unsat_res_unc = T_res['Unsaturated resistivity uncertainty'].astype(float).to_numpy()
        info['Resistivity']['unsat_res'] = unsat_res
        info['Resistivity']['unsat_res_unc'] = np.log10(unsat_res_unc) / 3
    except KeyError:
        # Fallback to saturated values if unsaturated are missing
        info['Resistivity']['unsat_res'] = res
        info['Resistivity']['unsat_res_unc'] = res_unc

    # Water table (optional)
    try:
        T_water = pd.read_excel(filename, sheet_name='Water table')
        info['Water Level'] = {
            'min': T_water['Min depth to water table'].astype(float).to_numpy(),
            'max': T_water['Max depth to water table'].astype(float).to_numpy()
        }
    except Exception:
        pass  # Water table is optional

    return info, cmaps
