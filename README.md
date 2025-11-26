# GeoPrior1D

Prior generator developed for the INTEGRATE project.



GeoPrior1D is an open-source tool for generating ensembles of one-dimensional (1D) geological and geophysical models that explicitly represent prior models for probabilistic inversion. Instead of relying on analytical prior expressions, GeoPrior1D defines priors through a probabilistic generator that produces random 1D realizations consistent with user-specified geological rules. These rules capture conceptual understanding of subsurface architecture — such as geological successions, layer thickness distributions, lithology–resistivity relationships, and groundwater levels corresponding to different geological settings. The resulting ensemble forms a statistically defined prior model that can be directly used in probabilistic inversion or uncertainty analysis. GeoPrior1D includes a graphical interface for configuration and visualization. It outputs reproducible HDF5 files and is implemented in MATLAB and Python under the MIT license. Together, these elements provide a transparent and flexible framework for linking geological knowledge with quantitative geophysical modeling.





--------------------------------------------------------------------------------------------------------

GeoPrior1DApp Executable



Prerequisites: 

MATLAB Runtime(R2023a) is installed.   

Download and install the Windows version of the MATLAB Runtime for R2023a from the following link on the

MathWorks website: https://www.mathworks.com/products/compiler/mcr/index.html





--------------------------------------------------------------------------------------------------------

GeoPrior1DApp MATLAB



Prerequisites:

MATLAB version 2023a or newer 





--------------------------------------------------------------------------------------------------------

GeoPrior1DApp Python



The Python module provides a command-line interface and Python API for generating 1D geological priors (not a GUI).

Install from PyPI:
```bash
pip install geoprior1d
```

For detailed information, including usage examples and API documentation, please see:

[geoprior1d/README.md](geoprior1d/README.md)





