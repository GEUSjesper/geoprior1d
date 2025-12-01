# main.py

from prior_generator import prior_generator

# Set parameters
input_file = "daugaard_standard.xlsx"
Nreals = 10000
dmax = 90
dz = 1
doPlot = 1

# Run prior generator
filename, flag_vector = prior_generator(input_file, Nreals, dmax, dz, doPlot)
print("Done! Output saved to:", filename)