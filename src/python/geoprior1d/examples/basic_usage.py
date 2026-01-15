"""Basic usage example for geoprior1d."""

from geoprior1d import geoprior1d

# Set parameters
input_file = "data/daugaard_matlab.xlsx"
n_realizations = 10000
depth_max = 90
depth_step = 1
plot = True

# Run geoprior1d
filename, flag_vector = geoprior1d(
    input_data=input_file,
    Nreals=n_realizations,
    dmax=depth_max,
    dz=depth_step,
    doPlot=1 if plot else 0
)

print(f"\n✓ Generated {n_realizations} realizations")
print(f"✓ Output file: {filename}")

if flag_vector[0] == 1:
    print("⚠️  Warning: Some constraints could not be satisfied")
print(f"✓ Average constraint satisfaction attempts: {flag_vector[2]:.1f}")