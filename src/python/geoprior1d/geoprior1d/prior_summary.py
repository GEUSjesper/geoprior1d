import numpy as np
import h5py
import matplotlib.pyplot as plt
from matplotlib import colors


def counts_modes(lithology):
    """
    Takes a list of 1-D lithology models and returns the marginal distribution
    and the modal distribution.
    """
    types = np.array(list(set(lithology.flatten())))
    number_of_types = len(types)
    
    counts = np.zeros((len(lithology[0]), number_of_types))
    for i, _ in enumerate(counts):
        for j, l_type in enumerate(types):
            row = lithology[:, i]
            mask = row == l_type
            counts[i, j] = sum(mask)
    
    
    mode_index = np.argmax(counts, axis=1)
    mode = types[mode_index]
    return counts, mode, number_of_types, types


def distribution_stats(lithology, depths):
    """
    Takes a 2-D array of lithology realizations and a 1-D array of depths and
    returns marginal distribution, modal distribution, entropy by depth,
    histogram over number of layers in each realization, and thickness of each
    layer, sorted by lithology type, across all realizations.
    """
    
    ### Marginal and modal distributions of lithology
    counts, mode, number_of_types, types = counts_modes(lithology)
    
    
    ### Entropy calculated for each depth
    entropy = np.zeros(len(lithology[0]))
    for i, _ in enumerate(entropy):
        p = counts[i, counts[i, :]!=0]/len(lithology)
        entropy[i] = -sum(p*np.log(p)/np.log(number_of_types))
    
    
    ### Histogram of number of layers for the models in lithology
    number_of_layers = np.sum(np.diff(lithology, axis=1)!=0, axis=1)+1
    edges = np.arange(min(number_of_layers)-1.5, max(number_of_layers)+2.5, 1)
    layer_counts = np.array([sum(np.logical_and(number_of_layers>edges[i],
                                                number_of_layers<edges[i+1]))
                             for i, _ in enumerate(edges[:-1])])
    
    
    
    ### Get the thicknesses of each layer
    
    z_thick = abs(depths[1]-depths[0]) # Add to the 0th layer
    
    # Save thicknesses to a dictionary, keyed by lithology class code
    thickness_dict = dict(zip(types, [[] for _ in types]))
    
    # lithology consists of arrays like [1 1 1 0 0 0 0 0 2 2 2 ...], the ints
    # being lithology class codes. Where the difference between neighbors is
    # not 0, the lithology changes. model_id is the row index, corresponding
    # to a specific realization. layer_id is the column index, specifying the
    # position of a layer change.
    model_id, layer_id = np.where(np.diff(lithology, axis=1)!=0)
    
    for i, model in enumerate(lithology):
        indices = layer_id[model_id==i]
        
        # indices locate the upper layer in a layer change. We need to also
        # know the lithology class of the last layer, so [-1] index is added.
        type_indices = np.concatenate((indices, [-1]))
        
        # The first layer change needs to be compared to the very top layer,
        # so [0] index is added.
        z_indices = np.concatenate(([0], type_indices))
        
        layer_thickness = np.diff(depths[z_indices])
        
        # The 0th saved thickness compares layers in the same lithology class.
        # This results in a z_thick too low thickness, compensated for here.
        layer_thickness[0] += z_thick
        
        # Go through all the layers and save the thickness to the dictionary,
        # keyed by lithology class code.
        for j, idx in enumerate(type_indices):
            thickness_dict[model[idx]].append(layer_thickness[j])

    return counts, mode, entropy, layer_counts, edges, thickness_dict

    

def prior_summary(file):
    """
    Takes path to a .h5-file with realization data and plots the modal
    distribution, a representative sample of the realizations, the marginal
    distribution of each lithology class, the entropy by depth, a histogram
    over the number of layers in each realization, and the distribution of
    layer thicknesses in each lithology class (darker=more frequent).
    """
    
    
    ### Saving relevant attributes as variables ###
    h5data = h5py.File(file, 'r')
    depths = h5data['M1'].attrs['x']
    cmap = h5data['M2'].attrs['cmap']
    lithology_types = h5data['M2'].attrs['class_name']
    resistivity = np.array(h5data['M1'])
    lithology = np.array(h5data['M2'])
    n_rows, n_cols = np.shape(resistivity)
    n_types = len(set(lithology_types))
    
    lithology_types = list(map(str, lithology_types))
    lithology_types = [x[2:-1] if (x[:2]=="b'" and x[-1]=="'") else x for x in lithology_types]
    
    
    ### Computes various statistics
    counts, mode, entropy, layer_counts, edges, thickness_dict = (
        distribution_stats(lithology, depths))
    
    
    ### Layer thickness histograms
    keys = thickness_dict.keys()
    histograms = []
    for key in keys:
        histograms.append(np.histogram(thickness_dict[key], density=True))
    
    
    ### Plotting the various statistics
    fig = plt.figure(figsize=(10, 6))
    gs = fig.add_gridspec(2, 5, width_ratios=[0.5, 0.5, 0.5, 1, 1])
    sgs2 = gs[0, 1:].subgridspec(1, 2, width_ratios=[1, 0.02], wspace=0.05)
    ax1 = fig.add_subplot(gs[0, 0])
    ax2 = fig.add_subplot(sgs2[0, 0])
    cax2 = fig.add_subplot(sgs2[0, 1])
    ax3 = fig.add_subplot(gs[1,:2])
    ax4 = fig.add_subplot(gs[1,2])
    ax5 = fig.add_subplot(gs[1,3])
    ax6 = fig.add_subplot(gs[1,4])
    
    
    ### Lithology colormap
    colmap = colors.ListedColormap(np.transpose(cmap))
    bounds = np.arange(1, n_types+2, 1)
    norm = colors.BoundaryNorm(bounds, colmap.N)
    
    ### Modal model
    ax1.set_title('Mode')
    ax1.set_ylabel('Depth [m]')
    modal_extent = [0, 1, max(depths), min(depths)]
    ax1.imshow(np.reshape(mode, (90,1)), interpolation='nearest', cmap=colmap, norm=norm, extent=modal_extent)
    ax1.set_aspect('auto')
    ax1.set_xticks([])
    
    ### All models
    ax2.set_title(f'Realizations, {min((100, n_rows))} shown out of {n_rows}')
    lith_extent = [1, min((100, n_rows)), max(depths), min(depths)]
    liths = ax2.imshow(np.transpose(lithology[:min((100, n_rows))]), interpolation='nearest', cmap=colmap, norm=norm, extent=lith_extent)
    ax2.set_aspect('auto')
    lith_ticks = np.arange(1.5, 1.5+n_types, 1)
    cbar = fig.colorbar(liths, cax=cax2, cmap=colmap, norm=norm, boundaries=bounds, ticks=lith_ticks)
    cbar.ax.invert_yaxis()
    cbar.ax.set_yticklabels(lithology_types)
    
    ### Marginal distribution
    ax3.set_title('Marginal distribution')
    ax3.set_ylabel('Depth [m]')
    marg_extent = [0, n_types, max(depths), min(depths)]
    pos = ax3.imshow(counts/max(counts.flatten()), interpolation='nearest', cmap='Blues', extent=marg_extent)
    ax3.set_aspect('auto')
    fig.colorbar(pos, ax=ax3)
    marg_ticks = np.arange(0.5, 0.5+n_types, 1)
    ax3.set_xticks(marg_ticks)
    ax3.set_xticklabels(lithology_types)
    ax3.tick_params(axis='x', labelrotation=90)
    
    ### Entropy by depth
    ax4.set_title('Entropy')
    ax4.set_ylabel('Depth [m]')
    ax4.set_xlabel('Entropy')
    ax4.plot(entropy, depths, color='black', linewidth=1.2)
    ax4.set_xlim([-0.015, 1])
    ax4.set_ylim([min(depths), max(depths)])
    ax4.yaxis.set_inverted(True)
    ax4.set_xticks([0, 0.5, 1])
    
    ### Number of layers histogram
    ax5.set_title('Number of layers')
    ax5.set_xlabel('Number of layers')
    ax5.set_ylabel('Number of realizations')
    bar_width = edges[1]-edges[0]
    ax5.bar(edges[:-1], layer_counts, width=bar_width, align='edge', edgecolor='black')
    
    ### Layer thickness histograms
    ax6.set_title('Layer thickness distribution')
    ax6.set_ylabel('Thickness [m]')
    bin_min = np.min([min(x[1]) for x in histograms])
    bin_max = np.max([max(x[1]) for x in histograms])
    span = bin_max-bin_min
    image_rows = int(span)+1
    bins = np.linspace(bin_min, bin_max, image_rows)
    hist_image = []
    for key in keys:
        hist_image.append(np.histogram(thickness_dict[key], bins=bins, density=False)[0])
    
    for i, x in enumerate(hist_image):
        if sum(x):
            hist_image[i] = x/max(x)
    hist_image = np.transpose(np.array(hist_image))
    
    
    axes_extents = [0, n_types, bin_max, bin_min]
    ax6.imshow(hist_image, interpolation='nearest', cmap='Blues', extent=axes_extents)
    ax6.set_aspect('auto')
    ax6.set_xticks(marg_ticks)
    ax6.set_xticklabels(lithology_types)
    ax6.tick_params(axis='x', labelrotation=90)
    
    
    
    plt.tight_layout()
    plt.show()
    pass