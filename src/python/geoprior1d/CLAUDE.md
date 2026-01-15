# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**geoprior1d** is a Python package for generating stochastic realizations of 1D subsurface lithology and resistivity models. It reads geological constraints from Excel files and generates Monte Carlo samples of layered earth models with associated resistivity values, optionally including water table effects.

The code has been structured as a proper Python module with:
- Clean package structure following best practices
- Command-line interface (`geoprior1d` command)
- Easy installation via pip
- Public API for programmatic use

## Core Architecture

### Main Pipeline

The generation pipeline follows this flow:

1. **Input Processing** (`extract_prior_info.py`): Reads Excel file with 3-4 sheets:
   - `Geology1`: Lithological classes with thickness constraints and RGB colors
   - `Geology2`: Geological sections/units with layer probabilities and frequencies
   - `Resistivity`: Resistivity values and uncertainties for each class (saturated + unsaturated)
   - `Water table` (optional): Water level depth constraints

2. **Prior Generation** (`get_prior_sample.py`): Orchestrates generation of N realizations:
   - Calls `prior_lith_reals()` to generate lithology with layer constraints
   - Calls `prior_water_reals()` to sample water table depth (if applicable)
   - Calls `prior_res_reals()` to assign resistivities based on lithology and water saturation

3. **Output** (`prior_generator.py`): Saves to HDF5 format with:
   - M1: Resistivity realizations (float32, log-scaled colormap)
   - M2: Lithology realizations (int16, discrete classes)
   - M3: Water level realizations (optional, float32)
   - Metadata attributes preserving input tables

### Key Components

- **`prior_lith_reals.py`**: Complex stochastic layer generator
  - Handles hierarchical geological sections with repeating/non-repeating layers
  - Enforces thickness constraints per class and section
  - Uses rejection sampling (up to 1000 tries) to satisfy all constraints
  - Tracks layer indices for spatially-correlated resistivity assignment

- **`prior_res_reals.py`**: Resistivity assignment
  - Assigns resistivities per-layer (not per-cell) for spatial correlation
  - Uses log-normal distribution: `10^(log10(μ) + σ * randn())`
  - Applies unsaturated resistivity above water table
  - Weighted averaging at water table crossing interval

- **`flj_log.py`**: Custom log-scale colormap for resistivity visualization
  - Designed by Flemming Jørgensen
  - Optimized for range [0.1, 2600] Ohm-m

## Installation

```bash
# Development installation
pip install -e .

# Or from PyPI (when published)
pip install geoprior1d
```

## Running the Code

### Command Line:
```bash
# Copy example file and show usage help (doesn't run, just prepares the file)
geoprior1d

# Then run with the copied example file
geoprior1d daugaard_standard.xlsx --plot

# Or use your own input file
geoprior1d input.xlsx -n 10000 -d 90 --plot

# With custom output filename
geoprior1d input.xlsx -n 10000 -d 90 -o my_output.h5

# With parallel processing (use all CPU cores)
geoprior1d input.xlsx -n 10000 -d 90 -j -1

# Full options
geoprior1d input.xlsx --n-realizations 10000 --depth-max 90 --depth-step 1 --plot --n-processes 4 --output result.h5

# Get help
geoprior1d --help
```

### Python API:
```python
from geoprior1d import geoprior1d

# Parameters
input_file = "daugaard_matlab.xlsx"  # Input Excel file
Nreals = 10000                        # Number of realizations
dmax = 90                             # Maximum depth (m)
dz = 1                                # Depth discretization (m)
doPlot = 1                            # Show plots (0=no, 1=yes)
n_processes = None                    # Parallel processes (None=sequential, -1=all cores, >0=specific number)
output_file = None                    # Custom output filename (None=auto-generate with timestamp)

# Generate
filename, flag_vector = geoprior1d(input_file, Nreals, dmax, dz, doPlot, n_processes, output_file)
```

### Dependencies
Automatically installed via pip: `numpy`, `h5py`, `matplotlib`, `pandas`, `scipy`, `tqdm`

## Input File Format

Excel files must contain specific sheet structures:

### Geology1 Sheet
Columns: `Class`, `Min thickness`, `Max thickness`, `RGB color`
- RGB color format: "R,G,B" (e.g., "255,128,0")

### Geology2 Sheet
Columns: `Classes`, `Probabilities`, `Min no of layers`, `Max no of layers`, `Min unit thickness`, `Max unit thickness`, `Frequency`, `Repeat`, `Min depth`
- `Classes`: Comma-separated class IDs (e.g., "1,2,3")
- `Probabilities`: Comma-separated weights (e.g., "0.5,0.3,0.2") or "1" for uniform
- `Frequency`: Probability that this section occurs (0-1)
- `Repeat`: 0 = allow adjacent identical layers, 1 = force alternation

### Resistivity Sheet
Columns: `Resistivity`, `Resistivity uncertainty`, `Unsaturated resistivity`, `Unsaturated resistivity uncertainty`
- Uncertainty is specified as the factor for 3σ range (converted internally to log-normal σ)

### Water table Sheet (optional)
Columns: `Min depth to water table`, `Max depth to water table`

## Output Format

HDF5 files named: `{input_base}_N{Nreals}_dmax{dmax}_{timestamp}.h5`

Each dataset includes attributes for visualization:
- `is_discrete`: 0 for continuous, 1 for categorical
- `name`: Display name
- `x`: Depth vector
- `clim`: Color axis limits
- `cmap`: RGB colormap array

File-level attributes preserve the original Excel tables as flattened arrays.

## Important Implementation Notes

1. **Resistivity correlation**: Resistivity is sampled per-layer (constant within each geological layer), not per-depth-cell. This creates realistic spatial correlation.

2. **Constraint satisfaction**: The lithology generator uses rejection sampling with increasing tolerance after 100 tries. Flag vector tracks issues:
   - `flag_vector[0]`: 1 if max tries exceeded (1000)
   - `flag_vector[1]`: Currently unused
   - `flag_vector[2]`: Average number of tries needed

3. **Water table handling**:
   - Unsaturated resistivity applied above water level
   - Depth cells that cross the water table use weighted averaging
   - If no water table sheet exists, saturated resistivity used everywhere

4. **Probability handling**: If `Probabilities` column contains "1", it's interpreted as uniform distribution over all classes in that section.

## File Structure

```
geoprior1d/
├── setup.py                      # Installation configuration
├── requirements.txt              # Dependencies
├── README.md                     # User documentation
├── CLAUDE.md                     # This file
├── geoprior1d/                   # Main package
│   ├── __init__.py               # Package initialization & public API
│   ├── core.py                   # Main prior_generator function
│   ├── io.py                     # Excel parsing (extract_prior_info)
│   ├── sampling.py               # Sample generation orchestrator
│   ├── lithology.py              # Lithology realization generator
│   ├── resistivity.py            # Resistivity realization generator
│   ├── water.py                  # Water level sampler
│   ├── colormaps.py              # Custom colormap (flj_log)
│   ├── visualization.py          # Plotting functions
│   └── cli.py                    # Command-line interface
├── examples/
│   ├── basic_usage.py            # Example script
│   └── data/
│       ├── *.xlsx                # Example input files
│       └── reference/            # Reference data
└── tests/                        # Unit tests (for future)
```

## Visualization

When `doPlot=1`, generates two matplotlib figures:
1. **Resistivity distributions**: PDF plots for each lithology class (saturated + unsaturated)
2. **Realizations**: First 100 realizations shown as image plots with lithology and resistivity
