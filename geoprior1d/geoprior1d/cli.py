"""Command-line interface for geoprior1d."""

import argparse
import os
import shutil
from pathlib import Path
from .core import geoprior1d
from . import __version__


def main():
    """Main CLI entry point."""
    parser = argparse.ArgumentParser(
        description="Generate 1D geological prior realizations",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter
    )

    parser.add_argument(
        "input_file",
        type=str,
        nargs='?',
        default=None,
        help="Path to Excel input file with geological constraints (default: copies daugaard_standard.xlsx to current directory)"
    )

    parser.add_argument(
        "-n", "--n-realizations",
        type=int,
        default=1000,
        help="Number of realizations to generate"
    )

    parser.add_argument(
        "-d", "--depth-max",
        type=float,
        default=90,
        help="Maximum depth in meters"
    )

    parser.add_argument(
        "-s", "--depth-step",
        type=float,
        default=1.0,
        help="Depth discretization step in meters"
    )

    parser.add_argument(
        "-p", "--plot",
        action="store_true",
        help="Display visualization plots"
    )

    parser.add_argument(
        "-j", "--n-processes",
        type=int,
        default=-1,
        metavar="N",
        help="Number of parallel processes (-1=all cores [default], 0=sequential, >0=specific number)"
    )

    parser.add_argument(
        "-o", "--output",
        type=str,
        default=None,
        metavar="FILE",
        help="Output HDF5 filename (default: auto-generated with timestamp)"
    )

    parser.add_argument(
        "-v", "--version",
        action="version",
        version=f"%(prog)s {__version__}"
    )

    args = parser.parse_args()

    # Handle default input file
    input_file = args.input_file
    if input_file is None:
        # Get the path to the example file in the package
        package_dir = Path(__file__).parent.parent
        example_file = package_dir / "examples" / "data" / "daugaard_standard.xlsx"

        if not example_file.exists():
            print(f"Error: Default example file not found at {example_file}")
            return

        # Copy to current working directory
        target_file = "daugaard_standard.xlsx"

        if os.path.exists(target_file):
            print(f"Example file '{target_file}' already exists in current directory.\n")
        else:
            shutil.copy(example_file, target_file)
            print(f"Copied example file to '{target_file}' in current directory.\n")

        # Show help and usage suggestion instead of running
        parser.print_help()
        print(f"\n{'='*70}")
        print("To run with the example file, try:")
        print(f"  geoprior1d {target_file}")
        print(f"  geoprior1d {target_file} --plot")
        print(f"  geoprior1d {target_file} -n 10000 -d 90 --plot")
        print(f"{'='*70}")
        return

    # Run geoprior1d
    filename, flag_vector = geoprior1d(
        input_data=input_file,
        Nreals=args.n_realizations,
        dmax=args.depth_max,
        dz=args.depth_step,
        doPlot=1 if args.plot else 0,
        n_processes=args.n_processes,
        output_file=args.output
    )

    print(f"\nDone! Output saved to: {filename}")

    if flag_vector[0] == 1:
        print("⚠️  Warning: Max iterations exceeded. Check constraints.")


if __name__ == "__main__":
    main()
