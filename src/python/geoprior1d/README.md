# geoprior1d

[![PyPI version](https://badge.fury.io/py/geoprior1d.svg)](https://badge.fury.io/py/geoprior1d)
[![Python versions](https://img.shields.io/pypi/pyversions/geoprior1d.svg)](https://pypi.org/project/geoprior1d/)
[![License](https://img.shields.io/pypi/l/geoprior1d.svg)](LICENSE)

1D geological prior generator for stochastic lithology and resistivity modeling.

## Installation

### From PyPI
```bash
pip install geoprior1d
```

### From source
```bash
cd geoprior1d

# Basic installation
pip install .

# Development installation (editable mode)
pip install -e .
```

## Quick Start

### Command Line

```bash
# Copy example file and show usage (doesn't run, just prepares the file)
geoprior1d

# Then run with the copied example file
geoprior1d daugaard_standard.xlsx --plot

# Or use your own input file
geoprior1d input.xlsx -n 10000 -d 90 --plot

# With custom output filename
geoprior1d input.xlsx -n 10000 -d 90 -o my_output.h5

# With parallel processing (use all CPU cores)
geoprior1d input.xlsx -n 10000 -d 90 -j -1

# All options combined
geoprior1d input.xlsx -n 10000 -d 90 -s 1 --plot -j 4 -o output.h5
```

### Python API

```python
from geoprior1d import geoprior1d

# Generate priors
filename, flags = geoprior1d(
    input_data="daugaard_matlab.xlsx",
    Nreals=10000,
    dmax=90,
    dz=1,
    doPlot=1,
    n_processes=None,      # Optional: use -1 for all cores, or specify number
    output_file=None       # Optional: specify custom output filename
)

print(f"Output saved to: {filename}")
```

## Input File Format

See [CLAUDE.md](CLAUDE.md) for detailed format specification and code architecture.

## Requirements

- Python >= 3.8
- numpy >= 1.20.0
- h5py >= 3.0.0
- matplotlib >= 3.3.0
- pandas >= 1.2.0
- scipy >= 1.6.0
- tqdm >= 4.60.0
- openpyxl >= 3.0.0

All dependencies are automatically installed via pip.

## License

MIT License
