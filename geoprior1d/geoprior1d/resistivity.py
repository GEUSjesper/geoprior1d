import numpy as np

def prior_res_reals(info, m, o, layer_index, z_vec):

    # Initialize n vector
    n = m.copy()
    if o != z_vec[0]:
        n_unsat = n.copy()
    else:
        n_unsat = None

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
        if o != z_vec[0]:
            unsat_value = 10 ** (np.log10(info['Resistivity']['unsat_res'][lithology_class-1])
                                + info['Resistivity']['unsat_res_unc'][lithology_class-1]
                                * np.random.randn())
            n_unsat[layer_mask] = unsat_value

    # Apply unsaturated values above water table
    if o != 0:
        n[z_vec < o] = n_unsat[z_vec < o]

        diffs = z_vec - o
        idx = np.where(diffs[:-1] * diffs[1:] < 0)[0]  # find sign change crossing

        # Weighted mean in the interval containing the water table
        if idx.size > 0:
            i = idx[0]
            n[i+1] = (
                n_unsat[i+1] * abs(diffs[i]) + n[i+1] * diffs[i+1]
            ) / (abs(diffs[i]) + diffs[i+1])

    return n
