"""Quick test to verify geoprior1d functionality."""

from geoprior1d import geoprior1d, generate_prior_realizations
from geoprior1d.io import extract_prior_info
import numpy as np
import os

print("Testing geoprior1d module...")
print("-" * 50)

# Test with minimal parameters
input_file = "examples/data/daugaard_matlab.xlsx"
n_realizations = 10  # Small number for quick test
depth_max = 90
depth_step = 1

print(f"Input file: {input_file}")
print(f"Realizations: {n_realizations}")
print(f"Depth range: 0-{depth_max}m")
print("-" * 50)

# Example 1: Standard usage - generates HDF5 file
print("\n=== Example 1: Standard usage (with HDF5 output) ===")
try:
    filename, flag_vector = geoprior1d(
        input_data=input_file,
        Nreals=n_realizations,
        dmax=depth_max,
        dz=depth_step,
        doPlot=0
    )

    print("✓ SUCCESS!")
    print(f"✓ Generated {n_realizations} realizations")
    print(f"✓ Output file: {filename}")
    print(f"✓ File size: {os.path.getsize(filename) / 1024:.2f} KB")

    if flag_vector[0] == 1:
        print("⚠️  Warning: Some constraints could not be satisfied")
    print(f"✓ Average constraint satisfaction attempts: {flag_vector[2]:.1f}")

except Exception as e:
    print(f"✗ FAILED: {e}")
    import traceback
    traceback.print_exc()

# Example 2: Direct access to arrays without writing HDF5
print("\n" + "=" * 50)
print("=== Example 2: Get arrays directly (no HDF5 file) ===")
print("=" * 50)
try:
    # Step 1: Extract prior information from Excel file
    prior_struct, cmaps = extract_prior_info(input_file)

    # Step 2: Create depth vector
    z_vec = np.arange(depth_step, depth_max + depth_step, depth_step)

    # Step 3: Generate prior samples (returns arrays directly)
    # Note: generate_prior_realizations returns (lithology, resistivity, water, flags)
    M2, M1, M3, flag_vector = generate_prior_realizations(
        prior_struct,
        z_vec,
        n_realizations
    )

    print("✓ SUCCESS!")
    print(f"\n✓ Resistivity array (M1) shape: {M1.shape}")
    print(f"  - Dimensions: ({n_realizations} realizations × {M1.shape[1]} depth points)")
    print(f"  - Range: {M1.min():.2f} to {M1.max():.2f} Ohm-m")
    print(f"  - Mean: {M1.mean():.2f} Ohm-m")

    print(f"\n✓ Lithology array (M2) shape: {M2.shape}")
    print(f"  - Dimensions: ({n_realizations} realizations × {M2.shape[1]} depth points)")
    print(f"  - Classes present: {np.unique(M2).astype(int).tolist()}")

    if M3 is not None and M3.size > 0:
        print(f"\n✓ Water table array (M3) shape: {M3.shape}")
        print(f"  - Dimensions: ({n_realizations} water depth values)")
        print(f"  - Depth range: {M3.min():.2f} to {M3.max():.2f} m")
    else:
        print("\n✓ No water table data (M3 is None)")

    # Example: Access individual realizations
    print("\n--- Example realization #0 ---")
    print(f"First 10 resistivity values: {M1[0, :10]}")
    print(f"First 10 lithology classes: {M2[0, :10]}")
    if M3 is not None:
        print(f"First 10 water table depths: {M3[0] if M3.size > 0 else None}")

    # Example: Compute statistics
    print("\n--- Statistics across all realizations ---")
    print(f"Mean resistivity per depth:")
    mean_resistivity = M1.mean(axis=0)
    print(f"  At 0m: {mean_resistivity[0]:.2f} Ohm-m")
    print(f"  At {depth_max//2}m: {mean_resistivity[depth_max//2]:.2f} Ohm-m")
    print(f"  At {depth_max}m: {mean_resistivity[-1]:.2f} Ohm-m")

    if flag_vector[0] == 1:
        print("\n⚠️  Warning: Some constraints could not be satisfied")
    print(f"✓ Average constraint satisfaction attempts: {flag_vector[2]:.1f}")

except Exception as e:
    print(f"\n✗ FAILED: {e}")
    import traceback
    traceback.print_exc()

print("\n" + "=" * 50)
print("All tests complete!")
print("=" * 50)
