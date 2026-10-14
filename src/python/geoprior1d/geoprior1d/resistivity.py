import numpy as np

def prior_res_reals(info, m, o, layer_index, z_vec):

    # Initialize n vector
    n = m.copy()
    n_unsat = n.copy()

    # Input resistivities for each layer (vectorized - only iterate over existing layers)
    # Get unique layer indices that actually exist in the model
    unique_layers = np.unique(layer_index)

    for layer_id in unique_layers:
        # Get the lithology class for this layer (constant within each layer)
        layer_mask = layer_index == layer_id
        lithology_class = int(m[layer_mask][0])  # All cells in a layer have same class

        # Sample resistivity once for entire layer (creates spatial correlation)
        res_value = 10 ** (np.log10(info['Resistivity']['res'][lithology_class-1])
                          + info['Resistivity']['res_unc'][lithology_class-1]
                          * np.random.randn())
        n[layer_mask] = res_value

        # Unsaturated resistivity above water table
        # Keep the interleaved saturated/unsaturated draw order, including
        # dry models, so unaffected seeded realizations retain their values.
        unsat_value = 10 ** (np.log10(info['Resistivity']['unsat_res'][lithology_class-1])
                            + info['Resistivity']['unsat_res_unc'][lithology_class-1]
                            * np.random.randn())
        n_unsat[layer_mask] = unsat_value

    # Apply unsaturated values above water table
    if o != 0:
        # z_vec holds cell bottoms; the first cell starts at the surface.
        # Include equality so a cell ending at the water table is wholly
        # unsaturated. This also handles water below the sampled grid.
        bottoms = np.asarray(z_vec)
        tops = np.concatenate(([0.0], bottoms[:-1]))
        fraction = np.clip((o - tops) / (bottoms - tops), 0.0, 1.0)
        unsaturated = fraction == 1.0
        n[unsaturated] = n_unsat[unsaturated]
        crossing = (fraction > 0.0) & (fraction < 1.0)
        # Thickness-weighted arithmetic resistivity, as in the original
        # interior crossing calculation; retain its arithmetic ordering.
        above = o - tops[crossing]
        below = bottoms[crossing] - o
        n[crossing] = (n_unsat[crossing] * above + n[crossing] * below) / (above + below)

    return n
