"""
geoprior1d: 1D Geological Prior Generator

A Python package for generating stochastic realizations of subsurface
lithology and resistivity models based on geological constraints.
"""

try:
    from importlib.metadata import version, PackageNotFoundError
except ImportError:
    # Python < 3.8
    from importlib_metadata import version, PackageNotFoundError

try:
    __version__ = version("geoprior1d")
except PackageNotFoundError:
    # Package is not installed, fallback to a default version
    __version__ = "0.0.0.dev"

# Import main API functions
from .core import geoprior1d, generate_prior_realizations, save_prior_to_hdf5
from .io import extract_prior_info
from .sampling import get_prior_sample
from .colormaps import flj_log

# Define public API
__all__ = [
    "geoprior1d",
    "generate_prior_realizations",
    "save_prior_to_hdf5",
    "extract_prior_info",
    "get_prior_sample",
    "flj_log",
]
