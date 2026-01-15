function [info,cmaps] = extractPriorInfo(filename)

% Following section reads data from the spreadsheet and write them to a
% matlab structure. 
if endsWith(filename, '.xlsx')
    info.filename = filename(1:end-5);
elseif endsWith(filename, '.xls')
    info.filename = filename(1:end-4);
else
    info.filename = filename;
end


% Load in geology as classes
warning('OFF', 'MATLAB:table:ModifiedAndSavedVarnames')
T_geo1 = readtable(filename, 'Sheet', 'Geology1');
T_geo2 = readtable(filename, 'Sheet', 'Geology2');
T_res = readtable(filename, 'Sheet', 'Resistivity');

info.Classes.names = T_geo1.Class;
info.Classes.min_thick = str2double(string(T_geo1.MinThickness));
info.Classes.max_thick = str2double(string(T_geo1.MaxThickness));
n = numel(info.Classes.names);
cmaps.Classes = zeros(n,3);
for i = 1:n
    cmaps.Classes(i,:) = str2num(T_geo1.RGBColor{i})./255;
end
info.Classes.codes = 1:numel(info.Classes.names);


% Load in units as sections
info.Sections.N_sections = numel(T_geo2.Classes);     
info.Sections.types = cellfun(@str2num, T_geo2.Classes, 'UniformOutput', false);
info.Sections.probabilities = cellfun(@str2num, T_geo2.Probabilities, 'UniformOutput', false);
info.Sections.min_layers = str2double(string(T_geo2.MinNoOfLayers));  
info.Sections.max_layers = str2double(string(T_geo2.MaxNoOfLayers)); 
info.Sections.min_thick = str2double(string(T_geo2.MinUnitThickness)); 
info.Sections.max_thick = str2double(string(T_geo2.MaxUnitThickness)); 
info.Sections.frequency = str2double(string(T_geo2.Frequency)); 
info.Sections.repeat = str2double(string(T_geo2.Repeat));
info.Sections.min_depth = str2double(string(T_geo2.MinDepth));


% Load in resistivity information
info.Resistivity.res = str2double(string(T_res.Resistivity));
info.Resistivity.res_unc = str2double(string(T_res.ResistivityUncertainty));

% resistivity input format was changed for version 0.31, hence conversion:
info.Resistivity.res_unc = log10(info.Resistivity.res_unc)/3;


try
    info.Resistivity.unsat_res = str2double(string(T_res.UnsaturatedResistivity));
    info.Resistivity.unsat_res_unc = str2double(string(T_res.UnsaturatedResistivityUncertainty));
    info.Resistivity.unsat_res_unc = log10(info.Resistivity.unsat_res_unc)/3;
catch
    info.Resistivity.unsat_res = str2double(string(T_res.Resistivity));
    info.Resistivity.unsat_res_unc = str2double(string(T_res.ResistivityUncertainty));
end


% Load in water table information
try
    T_water = readtable(filename,'Sheet','Water table');
    info.WaterLevel.min = T_water.MinDepthToWaterTable;
    info.WaterLevel.max = T_water.MaxDepthToWaterTable;
catch

end
