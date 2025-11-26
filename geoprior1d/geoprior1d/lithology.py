import numpy as np
import random


def _check_layer_thickness_constraints(thick_sections, thick_layers, types_layers, class_max_thick, class_min_thick, tolerance=1.05):
    """Check if layer thicknesses violate min/max constraints.

    Returns:
        int: Number of constraint violations
    """
    checksum = 0
    for i in np.where(thick_sections != 0)[0]:
        idxs = np.array([t-1 for t in types_layers[i]])
        max_violations = np.sum(thick_layers[i] >= tolerance * class_max_thick[idxs])
        min_violations = np.sum(thick_layers[i] <= (1/tolerance) * class_min_thick[idxs])
        checksum += max_violations + min_violations
    return checksum


def _check_section_depth_constraints(thick_sections, N, min_depths):
    """Check if cumulative section depths meet minimum depth requirements.

    Returns:
        int: 1 if constraints violated, 0 otherwise
    """
    for i in range(1, N):
        if np.sum(thick_sections[:i]) < min_depths[i]:
            return 1
    return 0


def _generate_section_layers(i, is_active, info, existing_N_layers=None):
    """Generate layers for a single geological section.

    Args:
        i: Section index
        is_active: Whether this section should be generated (based on frequency)
        info: Geological information dictionary
        existing_N_layers: If provided, reuse this count instead of regenerating (default: None)

    Returns:
        tuple: (thick_section, N_layers_count, types_layer_list, thick_layer_array)
    """
    if not is_active:
        return 0, 0, [], np.array([])

    # Thickness of unit
    thick_section = np.random.rand() * (
        info['Sections']['max_thick'][i] - info['Sections']['min_thick'][i]
    ) + info['Sections']['min_thick'][i]

    # Number of layers (use existing if provided, otherwise regenerate)
    if existing_N_layers is not None:
        N_layers_count = existing_N_layers
    else:
        N_layers_count = np.random.randint(
            info['Sections']['min_layers'][i],
            info['Sections']['max_layers'][i] + 1)

    # Types of layers
    if info['Sections']['repeat'][i] == 1 or N_layers_count < 2:
        # Allow repeating layers or single layer
        types_layer_list = random.choices(
            info['Sections']['types'][i],
            weights=info['Sections']['probabilities'][i],
            k=N_layers_count)
    else:
        # Force alternation: no adjacent identical layers
        vec = [random.choices(
            info['Sections']['types'][i],
            weights=info['Sections']['probabilities'][i],
            k=1)[0]]
        for j in range(1, N_layers_count):
            available_types = [t for t in info['Sections']['types'][i] if t != vec[j-1]]
            available_probs = [p for t, p in zip(info['Sections']['types'][i],
                                                 info['Sections']['probabilities'][i])
                             if t != vec[j-1]]
            vec.append(random.choices(available_types, weights=available_probs, k=1)[0])
        types_layer_list = vec

    # Thicknesses of layers
    t_layers = []
    for t in types_layer_list:
        idx = t - 1
        t_layers.append(
            np.random.rand() * (info['Classes']['max_thick'][idx] - info['Classes']['min_thick'][idx])
            + info['Classes']['min_thick'][idx])
    thick_layer_array = np.array(t_layers)

    return thick_section, N_layers_count, types_layer_list, thick_layer_array


def prior_lith_reals(info, z, flag_vector):
    # Number of units
    N = info['Sections']['N_sections']

    # Initialize lithology vector
    types = info['Sections']['types'][N-1]
    probs = info['Sections']['probabilities'][N-1]
    choice = random.choices(types, weights=probs, k=1)[0]
    m = np.full_like(z, choice, dtype=float)

    # Initialize layer vector
    layer_count = 1
    layer_index = np.full_like(z, layer_count, dtype=int)
    layer_count += 1
    if N == 1:
        return m, layer_index, flag_vector

    # Random vector for frequency of layers
    r = np.random.rand(N-1)

    # Preallocate vectors
    thick_sections = np.zeros(N)
    N_layers = np.zeros(N-1, dtype=int)
    types_layers = [None] * (N-1)
    thick_layers = [None] * (N-1)

    # Initial draw using extracted function
    for i in range(N-1):
        is_active = r[i] <= info['Sections']['frequency'][i]
        thick_sections[i], N_layers[i], types_layers[i], thick_layers[i] = \
            _generate_section_layers(i, is_active, info)

    # Normalize thicknesses
    if N > 1:
        for i in np.where(thick_sections != 0)[0]:
            thick_layers[i] = thick_layers[i] / (np.sum(thick_layers[i]) / thick_sections[i])

    # Cache class constraints as numpy arrays (avoid recreating in every loop iteration)
    class_max_thick = np.array(info['Classes']['max_thick'])
    class_min_thick = np.array(info['Classes']['min_thick'])
    section_min_depths = np.array(info['Sections']['min_depth'])

    # Check initial constraints using helper functions
    tries = 1
    checksum_layers = _check_layer_thickness_constraints(
        thick_sections, thick_layers, types_layers, class_max_thick, class_min_thick)
    checksum_sections = _check_section_depth_constraints(
        thick_sections, N, section_min_depths)

    # Redraw loop
    while checksum_layers > 0 or checksum_sections > 0:
        # Regenerate all sections using extracted function
        for i in range(N-1):
            is_active = r[i] <= info['Sections']['frequency'][i]
            # Keep existing N_layers unless tries > 100, then allow regeneration
            existing_N = None if tries > 100 else N_layers[i]
            thick_sections[i], N_layers[i], types_layers[i], thick_layers[i] = \
                _generate_section_layers(i, is_active, info, existing_N_layers=existing_N)

        if N > 1:
            for i in np.where(thick_sections != 0)[0]:
                thick_layers[i] = thick_layers[i] / (np.sum(thick_layers[i]) / thick_sections[i])

        # Re-check constraints using cached arrays and helper functions
        checksum_layers = _check_layer_thickness_constraints(
            thick_sections, thick_layers, types_layers, class_max_thick, class_min_thick)
        checksum_sections = _check_section_depth_constraints(
            thick_sections, N, section_min_depths)

        tries += 1
        if tries > 1000:
            flag_vector[0] = 1
            break

    flag_vector[2] = flag_vector[2] + tries

    # Combine
    Ts_all = np.concatenate([arr for arr in thick_layers if arr.size > 0])
    types_all = np.concatenate([np.array(t) for t in types_layers if len(t) > 0])

    # Depths
    Ds = np.cumsum(Ts_all)

    # Fill results
    for i in range(len(types_all)-1, -1, -1):
        m[z <= Ds[i]] = types_all[i]
        layer_index[z < Ds[i]] = layer_count
        layer_count += 1

    return m, layer_index, flag_vector
