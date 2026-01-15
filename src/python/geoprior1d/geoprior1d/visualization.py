"""Visualization utilities for geoprior1d."""

import numpy as np
import matplotlib.pyplot as plt
from matplotlib.colors import ListedColormap, BoundaryNorm, LogNorm
from scipy.stats import norm
from .colormaps import flj_log

def plot_resistivity_distributions(info):
    plt.figure(figsize=(12, 8))
    plt.suptitle("Resistivity distributions", fontsize=24)
    codes = info['Classes']['codes']
    for i, code in enumerate(codes):
        x = np.linspace(-1, 4, 500)
        y1 = norm.pdf(x, np.log10(info['Resistivity']['res'][i]),
                          info['Resistivity']['res_unc'][i] * np.log10(info['Resistivity']['res'][i]))
        plt.subplot((len(codes) + 2) // 3, 3, i + 1)
        plt.plot(10**x, y1, 'k', label='saturated')
        if 'Water Level' in info:
            y2 = norm.pdf(x, np.log10(info['Resistivity']['unsat_res'][i]),
                              info['Resistivity']['unsat_res_unc'][i] * np.log10(info['Resistivity']['unsat_res'][i]))
            plt.plot(10**x, y2, 'r', label='unsaturated')
        plt.title(info['Classes']['names'][i])
        plt.xscale('log')
        plt.xlabel('Resistivity [Ohm-m]')
        plt.legend()
    plt.tight_layout()
    plt.show()


def plot_realizations(z_vec, ms, ns, os, info, cmaps, Nreals):
    nshow = min(Nreals, 100)

    # Discrete lithology colormap
    cmap_classes = ListedColormap(cmaps['Classes'])
    bounds = np.arange(0.5, len(info['Classes']['codes']) + 1.5, 1) 
    norm_classes = BoundaryNorm(bounds, cmap_classes.N)

    # Resistivity colormap (continuous, log scale)
    cmap_res = ListedColormap(flj_log())
    norm_res = LogNorm(vmin=0.1, vmax=2600)

    plt.figure(figsize=(10, 6))

    # Lithology
    plt.subplot(2, 1, 1)
    plt.imshow(ms[:nshow].T, aspect='auto',
               extent=[0.5, nshow + 0.5, z_vec[-1], z_vec[0]],
               cmap=cmap_classes, norm=norm_classes, interpolation='nearest')
    plt.title("Lithostratigraphy")
    plt.ylabel("Depth [m]")
    cbar = plt.colorbar(ticks=info['Classes']['codes'], label='Lithology Class')
    cbar.ax.set_yticklabels(info['Classes']['names'])

    if 'Water Level' in info:
        for i in range(nshow):
            plt.plot([i+0.5, i + 1.5], [os[i], os[i]], 'k-')

    # Resistivity
    plt.subplot(2, 1, 2)
    plt.imshow(ns[:nshow].T, aspect='auto',
               extent=[0.5, nshow + 0.5, z_vec[-1], z_vec[0]],
               cmap=cmap_res, norm=norm_res, interpolation='nearest')
    plt.title("Resistivity")
    plt.xlabel("Realization #")
    plt.ylabel("Depth [m]")
    plt.colorbar(label='Resistivity [Ohm-m]')

    if 'Water Level' in info:
        for i in range(nshow):
            plt.plot([i+0.5, i + 1.5], [os[i], os[i]], 'k-')

    plt.tight_layout()
    plt.show()
