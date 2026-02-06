function [m, layer_index,flag_vector] = prior_lith_reals(info, z, flag_vector)


% Number of units
N = info.Sections.N_sections;


% Initialize lithology vector
% (Some tinkering nescessary due to the behavior of randsample)
m = randsample(repmat(info.Sections.types{N}, 1, 2), 1, 'true', repmat(info.Sections.probabilities{N}, 1, 2))*ones(size(z));


% Initialize layer vector
layer_count = 1;
layer_index = layer_count*ones(size(z));
layer_count = layer_count + 1;
if N == 1
    return
end


% random  vector for frequency of layers
r = rand(1, N-1);


% Prelocate vectors
thick_sections = zeros(1, N);
N_layers = zeros(1, N-1);
types_layers = cell(1, N-1);
thick_layers = cell(1, N-1);


% Draw all the values
for i = 1:N-1
    % If unit should be present in realization
    if r(i) <= info.Sections.frequency(i)


        % Randomly draw thickness of units
        thick_sections(i) = rand(1) * (info.Sections.max_thick(i) - info.Sections.min_thick(i)) + info.Sections.min_thick(i);            
        

        % Randomly draw number of layers
        N_layers(i) = randi(info.Sections.max_layers(i) - info.Sections.min_layers(i) + 1) + info.Sections.min_layers(i) - 1;               
              

        % Randomly draw layer types
        % If same layers are allowed to repeat
        if info.Sections.repeat(i) == 1 || N_layers(i) < 2  
            types_layers{i} = randsample(repmat(info.Sections.types{i}, 1, 1+N_layers(i)), N_layers(i), 'true',...
                repmat(info.Sections.probabilities{i}, 1, 1+N_layers(i)))';   
        % If same layers are not allowed to repeat   
        else    
            vec = randsample(info.Sections.types{i}, 1, 'true', info.Sections.probabilities{i}) * ones(1, N_layers(i));
            for j = 2:N_layers(i)
                vec(j) = randsample(repmat(info.Sections.types{i}(info.Sections.types{i} ~= vec(j-1)),1,2), 1, 'true',...
                    repmat(info.Sections.probabilities{i}(info.Sections.types{i} ~= vec(j-1)),1,2)); 
            end
            types_layers{i} = vec';
        end


        % Randomly draw thicknesses of layers  
        thick_layers{i} = rand(N_layers(i), 1) .* (info.Classes.max_thick(types_layers{i}) - info.Classes.min_thick(types_layers{i}))...
            + info.Classes.min_thick(types_layers{i});    
    
    
    % If unit should not be present in realization
    elseif r(i) > info.Sections.frequency(i)            
        thick_sections(i) = 0;
        N_layers(i) = 0;
        types_layers{i} = [];
        thick_layers{i} = [];
    end
end                  


% Make sure thicknesses fit within their intervals
if N > 1
    for i = find(thick_sections ~= 0)
        thick_layers{i} = thick_layers{i} ./ (sum(thick_layers{i}) / thick_sections(i));
    end
end


% Check if thicknesses are still within user specified settings
% (allowing +/- 5%)
tries = 1;
checksum_layers = 0;
for i = find(thick_sections ~= 0)
    layers_max_check = sum(thick_layers{i} >= 1.05 * info.Classes.max_thick(types_layers{i}));
    layers_min_check = sum(thick_layers{i} <= (1/1.05) * info.Classes.min_thick(types_layers{i})); 
    checksum_layers = checksum_layers + layers_max_check + layers_min_check;
end


% Check if min unit depth is fullfilled
checksum_sections = 0;
for i = 2:N
    if sum(thick_sections(1:i-1)) < info.Sections.min_depth(i) && thick_sections(i) ~= 0
        checksum_sections = 1;
        break
    end
end


% Do it all again if dimensions doesn't fit
while checksum_layers > 0 || checksum_sections > 0

    for i = 1:N-1
        % If unit should be present in realization
        if r(i) <= info.Sections.frequency(i)


            % if tried enough; draw a different number of layers and write a warning
            if tries > 100
                % Randomly draw number of layers
                N_layers(i) = randi(info.Sections.max_layers(i) - info.Sections.min_layers(i) + 1) + info.Sections.min_layers(i) - 1; 
                % flag_vector(2) = 1;
            end


            % Randomly draw thickness of sections
            thick_sections(i) = rand(1) * (info.Sections.max_thick(i) - info.Sections.min_thick(i)) + info.Sections.min_thick(i);                
            

            % Randomly draw layer types
            % If same layers are allowed to repeat
            if info.Sections.repeat(i) == 1 || N_layers(i) < 2  
                types_layers{i} = randsample(repmat(info.Sections.types{i},1,1+N_layers(i)), N_layers(i), 'true',...
                    repmat(info.Sections.probabilities{i},1,1+N_layers(i)))';
            % If same layers are not allowed to repeat
            else    
                vec = randsample(info.Sections.types{i}, 1, 'true', info.Sections.probabilities{i}) * ones(1,N_layers(i));
                for j = 2:N_layers(i)
                    vec(j) = randsample(repmat(info.Sections.types{i}(info.Sections.types{i} ~= vec(j-1)),1,2), 1, 'true',...
                        repmat(info.Sections.probabilities{i}(info.Sections.types{i} ~= vec(j-1)),1,2)); 
                end
                types_layers{i} = vec';
            end
            

            % Randomly draw thicknesses of layers 
            thick_layers{i} = rand(N_layers(i),1).*(info.Classes.max_thick(types_layers{i}) - info.Classes.min_thick(types_layers{i}))...
                + info.Classes.min_thick(types_layers{i});
    
        
        % If unit should not be present in realization
        elseif r(i) > info.Sections.frequency(i)
            thick_sections(i) = 0;
            N_layers(i) = 0;
            types_layers{i} = [];
            thick_layers{i} = [];
        end
    end          
    
    
    % Make sure thicknesses fit within their intervals
    if N > 1
        for i = find(thick_sections ~= 0)
            thick_layers{i} = thick_layers{i} ./ (sum(thick_layers{i}) / thick_sections(i));
        end
    end
    
    
    % Check if thicknesses are still within user specified settings
    % (allowing +/- 5%)
    checksum_layers = 0;
    for i = find(thick_sections ~= 0)
        layers_max_check = sum(thick_layers{i} >= 1.05 * info.Classes.max_thick(types_layers{i}));
        layers_min_check = sum(thick_layers{i} <= (1/1.05) * info.Classes.min_thick(types_layers{i})); 
        checksum_layers = checksum_layers + layers_max_check + layers_min_check;
    end


    % Check if min unit depth is fullfilled
    checksum_sections = 0;
    for i = 2:N
        if sum(thick_sections(1:i-1)) < info.Sections.min_depth(i) && thick_sections(i) ~= 0
            checksum_sections = 1;
            break
        end
    end


    % If 1000 loops; accept model and continue with a warning
    tries = tries + 1;
    if tries > 1000
        flag_vector(1) = 1;
        break
    end
end


flag_vector(3) = flag_vector(3) + tries;


% Combine into arrays
Ts_all = cat(1,thick_layers{:});
types_all = cat(1,types_layers{:});


% Convert layer thicknesses to depths
Ds = cumsum(Ts_all);


% Fill into m vector
for i = numel(types_all):-1:1
    m(z <= Ds(i)) = types_all(i);
    layer_index(z <= Ds(i)) = layer_count;
    layer_count = layer_count + 1;
end

