# GeoPrior1D

## **1. Introduction**
Prior generator developed for the INTEGRATE project

GeoPrior1D is an open-source tool for generating ensembles of one-dimensional (1D) geological and geophysical models that explicitly represent prior models for probabilistic inversion. Instead of relying on analytical prior expressions, GeoPrior1D defines priors through a probabilistic generator that produces random 1D realizations consistent with user-specified geological rules. These rules capture conceptual understanding of subsurface architecture — such as geological successions, layer thickness distributions, lithology–resistivity relationships, and groundwater levels corresponding to different geological settings. The resulting ensemble forms a statistically defined prior model that can be directly used in probabilistic inversion or uncertainty analysis. GeoPrior1D includes a graphical interface for configuration and visualization. It outputs reproducible HDF5 files and is implemented in MATLAB and Python under the MIT license. Together, these elements provide a transparent and flexible framework for linking geological knowledge with quantitative geophysical modeling.



## **2. GeoPrior1DApp Installation guides**

### **2.1 Executable**


Download and install the Windows version of the MATLAB Runtime for R2023a from the following link on the MathWorks website: https://www.mathworks.com/products/compiler/mcr/index.html

Run GeoPrior1DApp.exe in the GeoPriorApp folder



### **2.2 MATLAB**

Prerequisites:	MATLAB version 2023a or newer 

Open and run GeoPrior1DApp.m in the Matlab 1.0 folder



### **2.3 Python**

The Python module provides a command-line interface and Python API for generating 1D geological priors (not a GUI).

Install from PyPI:
```bash
pip install geoprior1d
```

For detailed information, including usage examples and API documentation, please see:

[geoprior1d/README.md](geoprior1d/README.md)



## **3.1 App UI walkthrough**
2. App Walkthrough 
A button-by-button walkthrough of all interactive features in the program. 
A: Filename: 
Filename of the excel file that contains the prior settings. Will automatically set if 
settings are imported or exported. The field is mostly a reminder for the user. 
B: No. of models: 
Number of models to generate when generating N priors. 
C: Depth: 
The maximum depth of the prior models in meters. Used when generating priors. 
D: dz: 
The thickness of the model parameters in the prior model. Used when generating 
priors. 
E: Open…: 
4
GeoPrior1D v.1.0 – User manual  
21st November 2025 
Imports prior settings from an excel file. Formatting in the excel file should be exact 
to be read correctly. If the file was generated using the “Save as” function of the 
PriorGeneratorApp this will be guaranteed. 
F: Save as…: 
Exports the current settings in the PriorGeneratorApp window to an excel file.  
G: Generate 100 prior samples: 
Generates 100 prior realizations using the current settings in the PriorGeneratorApp. 
Also visualizes the realizations in the “Visualization” section of the app UI. The 100 
generated realizations are saved to a HDF5 file labeled with the number of 
realizations, depth, and time of day (e.g. ‘prior_apptest_N100_dmax90_ 
20250919_1449.h5’). 
H: Generate N prior samples: 
Generates N prior realizations using the current settings in the PriorGeneratorApp. 
Also visualizes the first 100 realizations in the “Visualization” section of the app UI. 
The generated realizations are saved to a HDF5 file labeled with the number of 
realizations, depth, and time of day (e.g. ‘prior_apptest_N1000000_dmax90_ 
20250919_1449.h5’). 
I: Prior summary: 
After generating a prior file: Summarized key outcomes of the prior setup for user 
inspection such as mode, marginal distribution and entropy of the prior. 
J: Add class: 
Adds a class to the class data table with arbitrary properties.  
K: Remove class: 
Removes the selected row from the class data table. 
L: Class up/down: 
Moves the selected row from the class data table up or down. 
5
GeoPrior1D v.1.0 – User manual  
21st November 2025 
M: Resistivity histograms: 
Visualizes the resistivity inputs from the “Resistivity” and “Resist. Uncertainty” 
columns of the class data table. If “Add water table” is checked the unsaturated 
resistivities are also visualized. If not closed, the figure will live update as values are 
changed in the class data table. 
N: Add unit: 
Adds a unit to the unit data table with arbitrary properties.  
O: Remove unit: 
Removes the selected row from the unit data table. 
P: Class up/down: 
Moves the selected row from the class data table up or down. 
Q: Add water table: 
Adds the possibility to input properties related to the water table. Two new fields 
appear below that allows to specific the minimum and maximum depths to the water 
table in meters. Adds two additional rows to the class data table “Unsaturated res” 
and “Unsaturated res unc” that specifies the resistivity of the classes above the water 
table. 
R: Color assistant: 
The color field updates as soon as any field in the RGB column is edited. The button 
can be click to open up the catalogue of colors used in the Danish National well log 
database (Jupiter). 
S: Close app: 
Closes the program. 
T: Merge priors: 
Opens a new window where two priors generated using the app can be merged into 
one HDF5 file. If more than two priors wish to be merged, new priors can be merged 
with the already merged priors.  
6
GeoPrior1D v.1.0 – User manual  
21st November 2025 
U: Class data table: 
Input data related to the classes of the prior model. 
Class name: The name to attribute this class. 
Min thickness: The minimum thickness that this class is allowed to have in the prior 
realizations in meter (random thicknesses will be uniformly drawn between the 
minimum and maximum values). 
Max thickness: The maximum thickness that this class is allowed to have in the prior 
realizations in meter (random thicknesses will be uniformly drawn between the 
minimum and maximum values). 
Resistivity: The central value of the logarithmic-gaussian distribution of the resistivity 
in Ohm-m. 
Resist. Uncertainty: A factor that matches three standard deviations (3-σ) in the 
logarithmic space. This mimic the observed distribution when pooling real 
resistivity measurements. The choice of 3-σ makes it easier to limit the 
maximum and minimum values of the distribution as 99.7% of the distribution 
lies within 3-σ. 
RGB: The red, green, blue color code for the specific class. Values must be between 0 
and 255. 
Unsaturated res: The central value of the logarithmic-gaussian distribution of the class 
resistivity if the lithology is above the water table. 
Unsaturated res unc: A factor that matches three standard deviations (3-σ) in the 
logarithmic space if the lithology is above the water table. 
V: Unit data table: 
Input data related to the subsurface architecture of the prior model. 
Classes: The classes that should be generated within this unit. 
Probabilities: The probabilities of the respective classes. The probabilities must sum to 
1. Must have the same number of values as classes. Alternatively, the user can 
simply input 1 if all classes are equally likely. 
Min # layers: The minimum number of layers with the unit (random numbers will be 
uniformly drawn between the specified minimum and maximum values). 
Max # layers: The maximum number of layers with the unit (random numbers will be 
uniformly drawn between the specified minimum and maximum values). 
Min thickness: The minimum thickness of the unit (random thicknesses will be 
uniformly drawn between the minimum and maximum values). Keep in mind 
that there must be some consistency between the thicknesses chosen in the 
7
GeoPrior1D v.1.0 – User manual  
21st November 2025 
class data table and the thickness of the units. If not consistent the model 
might warp the uniform distribution of the class thicknesses severely. 
Max thickness: The maximum thickness of the unit (random thicknesses will be 
uniformly drawn between the minimum and maximum values). Keep in mind 
that there must be some consistency between the thicknesses chosen in the 
class data table and the thicknesses of the unit data table. If not consistent the 
model might warp the uniform distribution of the class thicknesses severely. 
Frequency: How often the unit should be generated in the prior model: 0 means the 
unit is in 0% of the generated models, 1 means that the unit is in 100% of the 
generated models.  
Repeat: Whether the same class is allowed to be drawn two times in a row. If 1 the 
next layer is completely randomly drawn. If 0 the next layer drawn must always 
be different than the previous layer.  
Min Depth: The minimum depth a unit is allowed to be present. Caution is advised 
when using this input as miss-matches with other inputs can cause a lot of 
redraws. 
W: Prior class visualization: 
Visualizes the lithologies of the first 100 prior models generated. If water table is part 
of the prior model it will be represented with small black lines indicating the depth to 
the water table. The x-axis is the prior realization numbers, and the y-axis is the 
depth. 
X: Prior resistivity visualization: 
Visualizes the resistivity of the first 100 prior models generated. If water table is part 
of the prior model it will be represented with small black lines indicating the depth to 
the water table. The x-axis is the prior realization numbers, and the y-axis is the 
depth. The colorscale is specially designed for resistivity visualization.



