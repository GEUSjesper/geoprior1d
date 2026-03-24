function [ClassData, UnitData, WaterData] = readTxt(filename)

lines = string(readlines(filename));

idx.Geology1   = find(lines == "Geology1-Resistivity");
idx.Geology2   = find(lines == "Geology2");
idx.WaterTable = find(lines == "WaterTable");

start_read = idx.Geology1 + 2;
stop_read  = idx.Geology2 - 2;

ClassData = {};

classNumber = 0;
for i = start_read:stop_read
    classNumber = classNumber + 1;
    cellValues = cellfun(@(x) strsplit(x, "\t"), cellstr(lines(i)), 'UniformOutput', false);

    % Correct formatting
    cellValues = cellValues{:};
    cellValues{2} = [str2num(cellValues{2})];
    cellValues{3} = [str2num(cellValues{3})];
    cellValues{4} = [str2num(cellValues{4})];
    cellValues{5} = [str2num(cellValues{5})];
    if ~isempty(idx.WaterTable)
        cellValues{7} = [str2num(cellValues{7})];
        cellValues{8} = [str2num(cellValues{8})];
    end
    
    ClassData = [ClassData; cellValues];
end


start_read = idx.Geology2 + 2;
if ~isempty(idx.WaterTable)
    stop_read = idx.WaterTable - 2;
else
    stop_read = numel(lines) - 1;
end

UnitData = {};

unitNumber = 0;
for i = start_read:stop_read
    unitNumber = unitNumber + 1;
    cellValues = cellfun(@(x) strsplit(x, "\t"), cellstr(lines(i)), 'UniformOutput', false);

    % % Correct formatting
    cellValues = cellValues{:};
    for j = 3:9
        cellValues{j} = [str2num(cellValues{j})];
    end
    
    UnitData = [UnitData; cellValues];
end


WaterData = {};
if ~isempty(idx.WaterTable)
    cellValues = cellfun(@(x) str2double(strsplit(x, "\t")), lines(idx.WaterTable + 2), 'UniformOutput', false);
    WaterData = cellValues{:};
end
