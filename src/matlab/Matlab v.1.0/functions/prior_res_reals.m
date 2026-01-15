function n = prior_res_reals(info, m, o, layer_index, z_vec)

% Initialize n vector
n = m;
if o ~= z_vec(1)
    n_unsat = n;
end


% Input resistivities for each layer
for i = 1:max(layer_index)
    for j = 1:max(info.Classes.codes)
        n(m == j & layer_index == i) =  10.^(log10(info.Resistivity.res(j)) + info.Resistivity.res_unc(j) * randn);

        % Check if there is an unsaturated resistivity and apply above the water table
        if o ~= z_vec(1)
            n_unsat(m == j & layer_index == i) =  10.^(log10(info.Resistivity.unsat_res(j)) + info.Resistivity.unsat_res_unc(j) * randn);
        end
    end
end


% Calculate the mean resistivity in the dz interval containing the water table
if o ~= 0
    n(z_vec < o) = n_unsat(z_vec < o);
    diffs = z_vec-o;
    idx = find(diffs(1:end-1).*diffs(2:end) < 0);


    % Weighted mean the interval with the water table
    if ~isempty(idx)
        n(idx+1) = (n_unsat(idx+1).*abs(diffs(idx)) + n(idx+1).*diffs(idx+1)) / (abs(diffs(idx)) + diffs(idx+1));
    end
end