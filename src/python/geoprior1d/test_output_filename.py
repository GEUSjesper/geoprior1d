"""Test the optional output_file parameter."""

from geoprior1d import geoprior1d
import os

print("Testing optional output filename parameter...")
print("=" * 60)

input_file = "examples/data/daugaard_matlab.xlsx"
n_realizations = 5  # Small number for quick test

# Test 1: Default behavior (auto-generated filename)
print("\nTest 1: Auto-generated filename (default behavior)")
print("-" * 60)
try:
    filename1, flag_vector1 = geoprior1d(
        input_data=input_file,
        Nreals=n_realizations,
        dmax=90,
        dz=1,
        doPlot=0
    )
    print(f"✓ Generated file: {filename1}")
    print(f"✓ File exists: {os.path.exists(filename1)}")
    print(f"✓ File size: {os.path.getsize(filename1) / 1024:.2f} KB")
except Exception as e:
    print(f"✗ FAILED: {e}")

# Test 2: Custom filename with .h5 extension
print("\nTest 2: Custom filename with .h5 extension")
print("-" * 60)
custom_filename = "my_custom_output.h5"
try:
    filename2, flag_vector2 = geoprior1d(
        input_data=input_file,
        Nreals=n_realizations,
        dmax=90,
        dz=1,
        doPlot=0,
        output_file=custom_filename
    )
    print(f"✓ Generated file: {filename2}")
    print(f"✓ File exists: {os.path.exists(filename2)}")
    print(f"✓ File size: {os.path.getsize(filename2) / 1024:.2f} KB")
    print(f"✓ Filename matches requested: {filename2 == custom_filename}")
except Exception as e:
    print(f"✗ FAILED: {e}")

# Test 3: Custom filename without .h5 extension (should auto-append)
print("\nTest 3: Custom filename without .h5 extension")
print("-" * 60)
custom_filename_no_ext = "my_output_no_extension"
try:
    filename3, flag_vector3 = geoprior1d(
        input_data=input_file,
        Nreals=n_realizations,
        dmax=90,
        dz=1,
        doPlot=0,
        output_file=custom_filename_no_ext
    )
    print(f"✓ Generated file: {filename3}")
    print(f"✓ File exists: {os.path.exists(filename3)}")
    print(f"✓ File size: {os.path.getsize(filename3) / 1024:.2f} KB")
    print(f"✓ .h5 extension added: {filename3.endswith('.h5')}")
    print(f"✓ Expected filename: {custom_filename_no_ext}.h5")
except Exception as e:
    print(f"✗ FAILED: {e}")

# Test 4: Custom filename with subdirectory
print("\nTest 4: Custom filename with subdirectory")
print("-" * 60)
subdir_filename = "output/test_subdir_output.h5"
try:
    # Create output directory if it doesn't exist
    os.makedirs("output", exist_ok=True)

    filename4, flag_vector4 = geoprior1d(
        input_data=input_file,
        Nreals=n_realizations,
        dmax=90,
        dz=1,
        doPlot=0,
        output_file=subdir_filename
    )
    print(f"✓ Generated file: {filename4}")
    print(f"✓ File exists: {os.path.exists(filename4)}")
    print(f"✓ File size: {os.path.getsize(filename4) / 1024:.2f} KB")
except Exception as e:
    print(f"✗ FAILED: {e}")

print("\n" + "=" * 60)
print("All tests complete!")
print("=" * 60)

# Cleanup
print("\nCleaning up test files...")
for fname in [filename1, filename2, filename3, filename4]:
    if os.path.exists(fname):
        os.remove(fname)
        print(f"✓ Removed: {fname}")

# Remove output directory if empty
if os.path.exists("output") and not os.listdir("output"):
    os.rmdir("output")
    print("✓ Removed empty output directory")

print("\n✓ Cleanup complete!")
