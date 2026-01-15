function o = prior_water_reals(info)

% Randomly draw water table
o = rand(1) * (info.WaterLevel.max - info.WaterLevel.min) + info.WaterLevel.min;
