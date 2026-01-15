function [counts, mode, E, layer_counts, thickness_counts, edges] = distribution_stats(ms, name)


types = h5readatt(name, '/M2', 'class_name');
z_vec = h5readatt(name, '/M1', 'x')';
n_types = numel(types);
[Nreals, Nz] = size(ms);


% Counts all classes
[mode, ~, ~, counts] = count_category_all(ms', 1:n_types);


% Calculate entropy
E = zeros(Nz,1);
for i = 1:Nz
    p = counts(i,counts(i,:) ~= 0)/Nreals;
    E(i) = -sum(p.*log(p)./log(n_types));
end


% Calculate number of layers
n_layers = sum(diff(ms') ~= 0) + 1;
edges = 0.5:1:max(n_layers) + 1.5;
layer_counts = histcounts(n_layers, edges);


% Calculate layer thicknesses
thickness_counts = zeros(Nz, n_types);


% Create a continious vector of ms with a 0 devider
ms_temp = [ms'; zeros(1, Nreals)]; 
ms_array = reshape(ms_temp, Nreals .* Nz + Nreals, 1);


%Create a corresponding z vector
zs_array = repmat([z_vec, 2*z_vec(end) - z_vec(end-1)], 1, Nreals);
z1 = -1;
for i = 1:n_types
    counter = 0;
    for j = 1:numel(ms_array)

        % Count if m is the correct lithology
        if ms_array(j) == i
            counter = counter + 1;
            if z1 == -1
                z1 = zs_array(j);
            end

        % Save thickness if layer is discontinued
        elseif ms_array(j) ~= i && counter > 0
            z2 = zs_array(j);
            layer_thickness = z2 - z1;
            idx = find(z_vec == layer_thickness);
            thickness_counts(idx, i) = thickness_counts(idx, i) + 1;
            counter = 0;
            z1 = -1;
        end
    end
end


