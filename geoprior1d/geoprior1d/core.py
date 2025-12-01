from .visualization import plot_resistivity_distributions, plot_realizations
import numpy as np
import h5py
import matplotlib.pyplot as plt
import pandas as pd
from .io import extract_prior_info
from .sampling import get_prior_sample
from .colormaps import flj_log
from scipy.stats import norm
from datetime import datetime
from matplotlib.colors import ListedColormap, BoundaryNorm, LogNorm
import os


def generate_prior_realizations(info, z_vec, Nreals, n_processes=-1):
    """
    Generate prior realizations of lithology, resistivity, and water level.

    This function performs pure data generation without any I/O operations.

    Args:
        info (dict): Prior information dictionary from extract_prior_info().
        z_vec (array): Depth vector (output from np.arange(dz, dmax + dz, dz)).
        Nreals (int): Number of realizations to generate.
        n_processes (int, optional): Number of parallel processes (default: -1).
            -1 = use all CPU cores (default, recommended for performance)
            0 or None = sequential execution (slower, for debugging)
            >0 = use specified number of cores

    Returns:
        ms (ndarray): Lithology realizations (Nreals x Nz).
        ns (ndarray): Resistivity realizations (Nreals x Nz).
        ws (ndarray): Water level realizations (Nreals,).
        flag_vector (list): Flags indicating issues during generation.
    """
    ms, ns, ws, flag_vector = get_prior_sample(info, z_vec, Nreals, n_processes)
    return ms, ns, ws, flag_vector


def save_prior_to_hdf5(output_file, ms, ns, ws, info, cmaps, z_vec, dmax, dz,
                       flag_vector, input_data):
    """
    Save prior realizations to HDF5 file.

    Args:
        output_file (str or None): Output HDF5 filename. If None, auto-generates
            filename with pattern: {input_base}_N{Nreals}_dmax{dmax}_{timestamp}.h5
        ms (ndarray): Lithology realizations (Nreals x Nz).
        ns (ndarray): Resistivity realizations (Nreals x Nz).
        ws (ndarray): Water level realizations (Nreals,).
        info (dict): Prior information dictionary.
        cmaps (dict): Colormap dictionary.
        z_vec (array): Depth vector.
        dmax (float): Maximum depth in meters.
        dz (float): Depth discretization step in meters.
        flag_vector (list): Flags from generation.
        input_data (str): Path to original Excel input file.

    Returns:
        name (str): Output HDF5 filename (actual saved filename).
    """
    Nreals = ms.shape[0]

    # Construct output filename
    if output_file is not None:
        # Use custom filename
        name = output_file
        # Ensure .h5 extension
        if not name.endswith('.h5'):
            name += '.h5'
    else:
        # Auto-generate filename
        base_name = info.get("filename", input_data)

        # Remove Excel extension if present
        base_name, _ = os.path.splitext(base_name)

        # Construct new filename
        timestamp = datetime.now().strftime("%Y%m%d_%H%M")
        name = f"{base_name}_N{Nreals}_dmax{dmax}_{timestamp}.h5"

    # Remove existing file
    if os.path.exists(name):
        os.remove(name)

    # Write HDF5 file
    with h5py.File(name, 'w') as f:

        # M1: Resistivity
        dset_M1 = f.create_dataset('M1', data=ns.astype(np.float32))
        dset_M1.attrs['is_discrete'] = 0
        dset_M1.attrs['name'] = 'Resistivity'
        dset_M1.attrs['x'] = np.arange(0, dmax, dz)
        dset_M1.attrs['clim'] = [.1, 2600]
        dset_M1.attrs['cmap'] = flj_log().T

        # M2: Lithology
        dset_M2 = f.create_dataset('M2', data=ms.astype(np.int16))
        dset_M2.attrs['is_discrete'] = 1
        dset_M2.attrs['name'] = 'Lithology'
        dset_M2.attrs['class_name'] = np.array(info['Classes']['names'], dtype='S')
        dset_M2.attrs['class_id'] = info['Classes']['codes']
        dset_M2.attrs['x'] = np.arange(0, dmax, dz)
        dset_M2.attrs['clim'] = [0.5, len(info['Classes']['codes']) + 0.5]
        dset_M2.attrs['cmap'] = cmaps['Classes'].T

        # M3: Water level
        if 'Water Level' in info:
            dset_M3 = f.create_dataset('M3', data=ws.astype(np.float32).reshape(-1, 1))
            dset_M3.attrs['is_discrete'] = 0
            dset_M3.attrs['name'] = 'Waterlevel'
            dset_M3.attrs['x'] = [0]

        # Read Excel sheets into DataFrames
        T_geo1 = pd.read_excel(input_data, sheet_name="Geology1")
        headers_geo1 = T_geo1.columns.astype(str).tolist()
        contents_geo1 = T_geo1.astype(str).values.flatten().tolist()

        T_geo2 = pd.read_excel(input_data, sheet_name="Geology2")
        headers_geo2 = T_geo2.columns.astype(str).tolist()
        contents_geo2 = T_geo2.astype(str).values.flatten().tolist()

        T_res = pd.read_excel(input_data, sheet_name="Resistivity")
        headers_res = T_res.columns.astype(str).tolist()
        contents_res = T_res.astype(str).values.flatten().tolist()

        # Open (or create) HDF5 file and write attributes
        with h5py.File(name, "a") as f:
            f.attrs["Creation date"] = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
            f.attrs["Class headers"] = headers_geo1
            f.attrs["Class table"] = contents_geo1
            f.attrs["Unit headers"] = headers_geo2
            f.attrs["Unit table"] = contents_geo2
            f.attrs["Resistivity headers"] = headers_res
            f.attrs["Resistivity table"] = contents_res

    return name


def geoprior1d(input_data, Nreals, dmax, dz, doPlot=0, n_processes=-1, output_file=None):
    """
    Generate 1D geological prior realizations and save to HDF5.

    This is the main function that orchestrates the entire workflow:
    1. Extract geological information from Excel file
    2. Generate prior realizations
    3. Save to HDF5 file
    4. Optionally plot results

    Args:
        input_data (str): Path to Excel input file with geological constraints.
        Nreals (int): Number of realizations to generate.
        dmax (float): Maximum depth in meters.
        dz (float): Depth discretization step in meters.
        doPlot (int): Display visualization plots (0=no, 1=yes).
        n_processes (int, optional): Number of parallel processes (default: -1).
            -1 = use all CPU cores (default, recommended for performance)
            0 or None = sequential execution (slower, for debugging)
            >0 = use specified number of cores
        output_file (str, optional): Output HDF5 filename. If None, auto-generates
            filename with pattern: {input_base}_N{Nreals}_dmax{dmax}_{timestamp}.h5

    Returns:
        name (str): Output HDF5 filename.
        flag_vector (list): Flags indicating issues during generation.
    """
    # Extract input parameters
    info, cmaps = extract_prior_info(input_data)

    # Create z vector
    z_vec = np.arange(dz, dmax + dz, dz)

    # Generate prior realizations
    ms, ns, ws, flag_vector = generate_prior_realizations(info, z_vec, Nreals, n_processes)

    # Save to HDF5 file
    name = save_prior_to_hdf5(output_file, ms, ns, ws, info, cmaps, z_vec, dmax, dz,
                              flag_vector, input_data)

    # Plotting
    if doPlot == 1:
        plot_resistivity_distributions(info)
        plot_realizations(z_vec, ms, ns, ws, info, cmaps, Nreals)

    return name, flag_vector
