function MergePriorH5s(input_name1, input_name2, output_name)
% Function for combining priors from the prior generator

f = dir(input_name1);
f(2) = dir(input_name2);


% Output name
if nargin < 3
    output_name = sprintf('%s_%s_merged.h5', input_name1, input_name2);
end


% Fetch M1 values
M1 = h5read(f(1).name, '/M1');
M1_is_discrete = h5readatt(f(1).name, '/M1','is_discrete');
M1_x = h5readatt(f(1).name, '/M1','x');
M1_clim = h5readatt(f(1).name, '/M1','clim');
M1_cmap = h5readatt(f(1).name, '/M1','cmap');
M1_name = h5readatt(f(1).name, '/M1','name');

% Append M1 values
M1 = [M1 h5read(f(2).name, '/M1')];


% Fetch M2 values
M2 = h5read(f(1).name, '/M2');
M2_is_discrete = h5readatt(f(1).name, '/M2', 'is_discrete');
M2_class_name = h5readatt(f(1).name, '/M2', 'class_name');
M2_class_id = h5readatt(f(1).name, '/M2', 'class_id');
M2_clim = h5readatt(f(1).name, '/M2', 'clim');
M2_cmap = h5readatt(f(1).name, '/M2', 'cmap');
M2_name = h5readatt(f(1).name, '/M2', 'name');
M2_x = h5readatt(f(1).name, '/M2', 'x');

% Append M2 values
M2_2 = h5read(f(2).name, '/M2');
M2_2_copy = M2_2;
M2_class_name_2 = h5readatt(f(2).name, '/M2', 'class_name');
M2_class_id_2 = h5readatt(f(2).name, '/M2', 'class_id');
M2_cmap_2 = h5readatt(f(2).name, '/M2', 'cmap');
for j = 1:numel(M2_class_name_2)

    % Check if any legend items are similar
    match = strcmp(M2_class_name_2(j), M2_class_name);

    % If non are the same, just append the new class information
    if ~any(match)
        M2_class_name(end+1) = M2_class_name_2(j);
        M2_class_id(end+1) = max(M2_class_id) + 1;
        M2_cmap(end+1,:) = M2_cmap_2(j,:);
        M2_clim(2) = M2_clim(2) + 1;
        M2_2(M2_2_copy == j) = M2_class_id(end);

    % If there is a match
    else
        M2_2(M2_2_copy == j) = find(match);
    end
end
M2 = [M2 M2_2];


% Check if /M3 is present in both files and fetch values
try
    h5read(f(1).name,'/M3');
    M3_in_one = true;
catch
    M3_in_one = false;
end

try
    h5read(f(2).name,'/M3');
    M3_in_two = true;
catch
    M3_in_two = false;
end


if M3_in_one && M3_in_two
    M3 = [h5read(f(1).name,'/M3') h5read(f(2).name,'/M3')];
    M3_name = h5readatt(f(1).name, '/M3', 'name');
    M3_is_discrete = h5readatt(f(1).name, '/M3', 'is_discrete');
    M3_x = h5readatt(f(1).name, '/M3', 'x');
elseif M3_in_one || M3_in_two
    fprintf('\nWater level info removed from combined prior.\n')
end


% Check if /M4 is already existing, and fetch values
try
    h5read(f(1).name,'/M4');
    M4_in_one = true;
catch
    M4_in_one = false;
end

try
    h5read(f(2).name,'/M4');
    M4_in_two = true;
catch
    M4_in_two = false;
end

if M4_in_one && M4_in_two
    M4_1 = h5read(f(1).name, '/M4');
    M4_name = h5readatt(f(1).name, '/M4', 'name');
    M4_is_discrete = h5readatt(f(1).name, '/M4', 'is_discrete');
    M4_prior_name_1 = h5readatt(f(1).name, '/M4', 'class_name');
    M4_prior_id_1 = h5readatt(f(1).name, '/M4', 'class_id');
    M4_x = h5readatt(f(1).name, '/M4', 'x');

    M4_2 = h5read(f(2).name, '/M4');
    M4_prior_name_2 = h5readatt(f(2).name, '/M4', 'class_name');
    M4_prior_id_2 = h5readatt(f(2).name, '/M4', 'class_id');

    M4_copy = [M4_1 -M4_2];
    M4 = zeros(size(M4_copy));
    M4_prior_id_copy = [M4_prior_id_1 -M4_prior_id_2];
    M4_prior_name = [M4_prior_name_1; M4_prior_name_2];
    M4_prior_id = 1:numel(M4_prior_name);

    for i = 1:numel(M4_prior_id_copy)
        M4(M4_copy == M4_prior_id_copy(i)) = M4_prior_id(i);
    end

elseif M4_in_one
    M4 = h5read(f(1).name, '/M4');
    M4_name = h5readatt(f(1).name, '/M4', 'name');
    M4_is_discrete = h5readatt(f(1).name, '/M4', 'is_discrete');
    M4_prior_name = h5readatt(f(1).name, '/M4', 'class_name');
    M4_prior_id = h5readatt(f(1).name, '/M4', 'class_id');
    M4_x = h5readatt(f(1).name, '/M4', 'x');
    M4 = [M4 (max(double(M4))+1) * ones(1,size(M2_2_copy, 2))];
    M4_prior_name = [M4_prior_name; string({f(2).name})];
    M4_prior_id(end+1) = max(M4);

elseif M4_in_two
    M4 = h5read(f(2).name, '/M4');
    M4_name = h5readatt(f(2).name, '/M4', 'name');
    M4_is_discrete = h5readatt(f(2).name, '/M4', 'is_discrete');
    M4_prior_name = h5readatt(f(2).name, '/M4', 'class_name');
    M4_prior_id = h5readatt(f(2).name, '/M4', 'class_id');
    M4_x = h5readatt(f(2).name, '/M4', 'x');

    M4 = [(max(double(M4))+1) * ones(1,size(h5read(f(1).name,'/M1'), 2)) M4];
    M4_prior_name = [string({f(1).name}); M4_prior_name];
    M4_prior_id = [max(M4); M4_prior_id];

else
    M4 = single([ones(1,size(h5read(f(1).name, '/M1'), 2)) 2*ones(1, size(h5read(f(2).name, '/M1'), 2))]);
    M4_name = 'Prior';
    M4_is_discrete = 1;
    M4_prior_name = string({f.name});
    M4_prior_id = [1 2];
    M4_x = 0;
end


% Write to Hdf5 file
try;delete(output_name);end
h5create(output_name, '/M1' ,size(M1), 'Datatype', 'single')
h5writeatt(output_name,'/','Creation date', date);
h5write(output_name,'/M1',M1)
h5writeatt(output_name,'/M1','is_discrete',M1_is_discrete)
h5writeatt(output_name,'/M1','x',M1_x);
h5writeatt(output_name,'/M1','clim',M1_clim);
h5writeatt(output_name,'/M1','cmap',M1_cmap);
h5writeatt(output_name,'/M1','name',M1_name);


h5create(output_name, '/M2', size(M2), 'Datatype', 'int16')
h5write(output_name,'/M2',M2)
h5writeatt(output_name,'/M2','is_discrete',M2_is_discrete);
h5writeatt(output_name,'/M2','class_name',M2_class_name);
h5writeatt(output_name,'/M2','class_id',M2_class_id);
h5writeatt(output_name,'/M2','clim',M2_clim);
h5writeatt(output_name,'/M2','cmap',M2_cmap);
h5writeatt(output_name,'/M2','name',M2_name);
h5writeatt(output_name,'/M2','x',M2_x);


if M3_in_one && M3_in_two
    h5create(output_name,'/M3',size(M3), 'Datatype', 'single')
    h5write(output_name,'/M3',M3)
    h5writeatt(output_name,'/M3','is_discrete',0);
    h5writeatt(output_name,'/M3','name',M3_name);
    h5writeatt(output_name,'/M3','is_discrete', M3_is_discrete);
    h5writeatt(output_name,'/M3','x', M3_x);
end


h5create(output_name, '/M4', size(M4), 'Datatype', 'int16')
h5write(output_name, '/M4', M4)
h5writeatt(output_name, '/M4', 'name', M4_name);
h5writeatt(output_name, '/M4', 'is_discrete', M4_is_discrete);
h5writeatt(output_name, '/M4', 'class_name', M4_prior_name);
h5writeatt(output_name, '/M4', 'class_id', M4_prior_id);
h5writeatt(output_name, '/M4', 'x', M4_x);
h5writeatt(output_name, '/M4', 'clim', [0.5 M4_prior_id(end)+0.5]);
h5writeatt(output_name, '/M4', 'cmap', hsv(numel(M4_prior_id)));
