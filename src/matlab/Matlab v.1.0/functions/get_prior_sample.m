function [ms,ns,os,flag_vector] = get_prior_sample(info,z_vec,Nreals)

% z_vec is depth to layer BOTTOMS

% Function to get prior sample
Nz = length(z_vec);         % Number of depths


% Prelocate vectors
ms = zeros(Nreals, Nz);      % Lithologi vector
ns = zeros(Nreals, Nz);      % Resistivity vector
os = zeros(Nreals, 1);       % Water level


% To report if issues arose during simulation
flag_vector = [0; 0; 0];


% Even probabilities if not specified
for i = 1:numel(info.Sections.probabilities)
    if info.Sections.probabilities{i} == 1
        info.Sections.probabilities{i} = ones(1,numel(info.Sections.types{i}))./numel(info.Sections.types{i});
    end
end


% Time running time and create waitbar
tic
wb = waitbar(0,'Please wait...', 'Name', 'Generating priors','CreateCancelBtn','setappdata(gcbf,''canceling'',1)');
setappdata(wb, 'canceling', 0);
pcts = linspace(1, Nreals, 100);
pcts = round(pcts);


for i = 1:Nreals
    
    if getappdata(wb,'canceling')
        break
    end

    
    % Assign lithologies
    [m, layer_index, flag_vector] = prior_lith_reals(info, z_vec, flag_vector);
    ms(i,:) = m;


    % Assign water table
    if isfield(info,'WaterLevel')
        o = prior_water_reals(info);
    else
        o = 0;
    end
    os(i) = o;


    % Assign resistivities
    n = prior_res_reals(info, m, o, layer_index, z_vec);
    ns(i,:) = n;


    % Display progress
    if any(pcts == i)
        waitbar(i/Nreals, wb, ['Estimated time remaining: ', num2str(round(toc*(Nreals/i-1))), ' seconds'])
    end

end


delete(wb);
toc


% Provide warnings if issues occured
if flag_vector(1) == 1
    warning('Something went wrong and models might not represent your inputs. Consider if depths and thicknesses are reasonably chosen.')
end

if flag_vector(2) == 1
    warning('Somewhat succesfull. Number of layers possibly not a uniformly drawn')
end

flag_vector(3) = flag_vector(3)/Nreals;