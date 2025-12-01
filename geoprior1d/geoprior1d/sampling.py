import numpy as np
import random
import time
from tqdm import tqdm
from multiprocessing import Pool, cpu_count
from functools import partial
from .lithology import prior_lith_reals
from .water import prior_water_reals
from .resistivity import prior_res_reals


def _generate_single_realization(i, info, z_vec, seed_offset=0):
    """
    Generate a single realization (worker function for multiprocessing).

    Args:
        i (int): Realization index
        info (dict): Prior information dictionary
        z_vec (array): Depth vector
        seed_offset (int): Random seed offset for reproducibility

    Returns:
        tuple: (m, n, o, local_flag_vector)
    """
    # Set unique random seed for this worker
    np.random.seed(seed_offset + i)
    random.seed(seed_offset + i)  # For Python's random module used in lithology.py

    # Initialize flag vector for this realization
    local_flag = [0, 0, 0]

    # Generate lithology
    m, layer_index, local_flag = prior_lith_reals(info, z_vec, local_flag)

    # Generate water level
    if 'Water Level' in info:
        o = prior_water_reals(info)
    else:
        o = 0

    # Generate resistivity
    n = prior_res_reals(info, m, o, layer_index, z_vec)

    return m, n, o, local_flag


def get_prior_sample(info, z_vec, Nreals, n_processes=-1):
    """
    Generate prior samples of lithology, resistivity, and water level.

    Args:
        info (dict): Prior information dictionary.
        z_vec (array-like): Depths to layer bottoms.
        Nreals (int): Number of realizations to generate.
        n_processes (int, optional): Number of parallel processes (default: -1).
            -1 = use all CPU cores (default, recommended for performance)
            0 or None = sequential execution (slower, for debugging)
            >0 = use specified number of cores

    Returns:
        ms (ndarray): Lithology samples (Nreals x Nz).
        ns (ndarray): Resistivity samples (Nreals x Nz).
        os (ndarray): Water level samples (Nreals,).
        flag_vector (list): Flags indicating issues during generation.
    """

    Nz = len(z_vec)
    # Use float32 for memory efficiency (half the memory of float64)
    ms = np.zeros((Nreals, Nz), dtype=np.float32)  # Lithology samples
    ns = np.zeros((Nreals, Nz), dtype=np.float32)  # Resistivity samples
    os = np.zeros(Nreals, dtype=np.float32)        # Water level samples
    flag_vector = [0, 0, 0]      # Simulation status flags

    # Note: Probability normalization now handled in extract_prior_info() preprocessing

    start_time = time.time()
    seed_offset = np.random.randint(0, 1e9)  # For reproducibility across runs

    # ========== PARALLEL EXECUTION ==========
    if n_processes is not None and n_processes != 0:
        # Determine number of workers
        if n_processes == -1:
            n_workers = cpu_count()
        else:
            n_workers = min(n_processes, cpu_count())

        print(f"Using {n_workers} parallel processes...")

        # Create worker function with fixed parameters
        worker = partial(_generate_single_realization,
                        info=info,
                        z_vec=z_vec,
                        seed_offset=seed_offset)

        # Process in parallel with progress bar
        with Pool(processes=n_workers) as pool:
            results = list(tqdm(
                pool.imap(worker, range(Nreals)),
                total=Nreals,
                desc="Generating priors",
                unit="real"
            ))

        # Unpack results
        for i, (m, n, o, local_flag) in enumerate(results):
            ms[i, :] = m
            ns[i, :] = n
            os[i] = o

            # Aggregate flags
            flag_vector[0] = max(flag_vector[0], local_flag[0])
            flag_vector[1] = max(flag_vector[1], local_flag[1])
            flag_vector[2] += local_flag[2]

    # ========== SEQUENTIAL EXECUTION ==========
    else:
        for i in tqdm(range(Nreals), desc="Generating priors", unit="real"):
            m, n, o, flag_vector = _generate_single_realization(
                i, info, z_vec, seed_offset
            )
            ms[i, :] = m
            ns[i, :] = n
            os[i] = o

    elapsed = time.time() - start_time
    print(f"Prior generation completed in {round(elapsed)} seconds.")

    # Final warnings if applicable
    if flag_vector[0] == 1:
        print("⚠️  Warning: Something went wrong. Models may not reflect your input assumptions.")
    if flag_vector[1] == 1:
        print("⚠️  Warning: Number of layers may not be uniformly distributed.")
    flag_vector[2] = flag_vector[2] / Nreals

    return ms, ns, os, flag_vector
