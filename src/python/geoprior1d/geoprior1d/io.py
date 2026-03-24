import os
import pandas as pd
import numpy as np

def extract_prior_info(filename):
    """
    Reads geological prior information from either an Excel file
    or a specifically formatted text file.

    Args:
        filename (str): Path to input file.

    Returns:
        info (dict): Structured information from the input file.
        cmaps (dict): RGB color mapping for geological classes.
    """
    ext = os.path.splitext(filename)[1].lower()

    if ext in ['.xlsx', '.xls']:
        return extract_prior_info_excel(filename)
    elif ext == '.txt':
        return extract_prior_info_txt(filename)
    else:
        raise ValueError(f"Unsupported file format: {ext}")
        
        
def extract_prior_info_excel(filename):
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


def extract_prior_info_txt(filename):
    """
    Reads geological prior information from a specifically formatted text file.

    The text file is expected to contain the sections:
        - Geology1-Resistivity
        - Geology2
        - WaterTable (optional)

    Returns:
        info (dict): Structured information from the text file.
        cmaps (dict): RGB color mapping for geological classes.
    """
    info = {}
    cmaps = {}

    # Read all non-empty lines
    with open(filename, "r", encoding="utf-8") as f:
        lines = [line.rstrip("\n\r") for line in f]

    lines_arr = np.array(lines, dtype=object)

    # Locate section headers
    idx_geo1 = np.where(lines_arr == "Geology1-Resistivity")[0]
    idx_geo2 = np.where(lines_arr == "Geology2")[0]
    idx_water = np.where(lines_arr == "WaterTable")[0]

    if len(idx_geo1) == 0 or len(idx_geo2) == 0:
        raise ValueError("Required sections 'Geology1-Resistivity' and/or 'Geology2' not found in text file.")

    idx_geo1 = idx_geo1[0]
    idx_geo2 = idx_geo2[0]
    idx_water = idx_water[0] if len(idx_water) > 0 else None

    # -------------------------
    # Read ClassData section
    # -------------------------
    start_read = idx_geo1 + 2
    stop_read = idx_geo2 - 2

    class_rows = []
    for i in range(start_read, stop_read + 1):
        row = lines[i].split("\t")
        class_rows.append(row)

    if len(class_rows) == 0:
        raise ValueError("No class data found between 'Geology1-Resistivity' and 'Geology2'.")

    # Convert to structured arrays
    class_names = [row[0] for row in class_rows]
    min_thick = np.array([float(row[1]) for row in class_rows], dtype=float)
    max_thick = np.array([float(row[2]) for row in class_rows], dtype=float)
    res = np.array([float(row[3]) for row in class_rows], dtype=float)
    res_unc_raw = np.array([float(row[4]) for row in class_rows], dtype=float)

    # RGB color column assumed to be column 6 in MATLAB indexing => row[5] in Python
    rgb_raw = [str(row[5]).strip() for row in class_rows]
    cmaps['Classes'] = np.array([
        np.fromstring(rgb_str, sep=',') / 255.0 for rgb_str in rgb_raw
    ])

    info['Classes'] = {
        'names': class_names,
        'min_thick': min_thick,
        'max_thick': max_thick,
        'codes': list(range(1, len(class_names) + 1))
    }

    info['Resistivity'] = {
        'res': res,
        'res_unc': np.log10(res_unc_raw) / 3
    }

    # Optional unsaturated resistivity columns if WaterTable section exists
    if idx_water is not None:
        try:
            unsat_res = np.array([float(row[6]) for row in class_rows], dtype=float)
            unsat_res_unc_raw = np.array([float(row[7]) for row in class_rows], dtype=float)
            info['Resistivity']['unsat_res'] = unsat_res
            info['Resistivity']['unsat_res_unc'] = np.log10(unsat_res_unc_raw) / 3
        except (IndexError, ValueError):
            info['Resistivity']['unsat_res'] = res
            info['Resistivity']['unsat_res_unc'] = info['Resistivity']['res_unc']
    else:
        info['Resistivity']['unsat_res'] = res
        info['Resistivity']['unsat_res_unc'] = info['Resistivity']['res_unc']

    # -------------------------
    # Read UnitData section
    # -------------------------
    start_read = idx_geo2 + 2
    stop_read = (idx_water - 2) if idx_water is not None else (len(lines) - 1)

    unit_rows = []
    for i in range(start_read, stop_read + 1):
        row = lines[i].split("\t")
        unit_rows.append(row)

    if len(unit_rows) == 0:
        raise ValueError("No unit/section data found in 'Geology2' section.")
    
    info['Sections'] = {
        'N_sections': len(unit_rows),
        'types': [list(map(int, str(row[0]).split(','))) for row in unit_rows],
        'probabilities': [list(map(float, str(row[1]).split(','))) for row in unit_rows],
        'min_layers': np.array([float(row[2]) for row in unit_rows], dtype=float),
        'max_layers': np.array([float(row[3]) for row in unit_rows], dtype=float),
        'min_thick': np.array([float(row[4]) for row in unit_rows], dtype=float),
        'max_thick': np.array([float(row[5]) for row in unit_rows], dtype=float),
        'frequency': np.array([float(row[6]) for row in unit_rows], dtype=float),
        'repeat': np.array([float(row[7]) for row in unit_rows], dtype=float),
        'min_depth': np.array([float(row[8]) for row in unit_rows], dtype=float),
    }

    # Normalize probabilities: convert "1" to uniform distribution
    for i in range(len(info['Sections']['probabilities'])):
        if len(info['Sections']['probabilities'][i]) > 0 and info['Sections']['probabilities'][i][0] == 1:
            n_types = len(info['Sections']['types'][i])
            info['Sections']['probabilities'][i] = (np.ones(n_types) / n_types).tolist()

    # -------------------------
    # Read optional WaterData
    # -------------------------
    if idx_water is not None:
        water_row = lines[idx_water + 2].split("\t")
        info['Water Level'] = {
            'min': np.array([float(water_row[0])], dtype=float),
            'max': np.array([float(water_row[1])], dtype=float)
        }

    return info, cmaps