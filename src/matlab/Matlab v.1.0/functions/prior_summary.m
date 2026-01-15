function dist = prior_summary(filename, mix)
rng(1);

% Whether the 100 samples should be the first 100 or random 100
% realizations.
if nargin < 2
    mix = 0;
end

% Load prior information and calculate other relevant values
z_vec = h5readatt(filename, '/M1', 'x')';
cmap = h5readatt(filename, '/M2', 'cmap');
types = h5readatt(filename, '/M2', 'class_name');
ns = h5read(filename, '/M1')';
ms = h5read(filename, '/M2')';
n_types = numel(types);
[Nr, Nm] = size(ms);


% Do calculations
[counts, mode, E, layer_counts, thickness_counts, edges] = distribution_stats(ms, filename);


% Make new figure
figure('Name', 'Summary', 'NumberTitle', 'off'); clf
tiledlayout(2, 7, 'TileSpacing', 'compact', 'Padding', 'tight');


% Plot mode
nexttile(1)
imagesc(ones(size(z_vec)),z_vec,mode')
clim([0.5 n_types+0.5]); xlim([0.5 1.5]); ylabel('Depth [m]');
title('Mode')
set(gca, 'xticklabels', [])
set(gca, 'fontsize', 12) 
set(gca, 'Colormap', cmap); 
clim([0.5 n_types+0.5]);


% Plot 100 models
nexttile(2, [1 6])
if mix == 1
    imagesc(1:min([Nr 100]), z_vec, ms(randperm(Nr, min([Nr 100])),:)')
else
    imagesc(1:min([Nr 100]), z_vec, ms(1:min([Nr 100]),:)')
end
clim([0.5 n_types+0.5]); xlim([0.5 100.5]);
set(gca, 'fontsize', 12) 
set(gca, 'Colormap', cmap)
clim([0.5 n_types+0.5]);
c = colorbar; set(c, 'YDir', 'reverse', 'xtick', 1:n_types, 'xticklabel', types, 'FontSize',12)
xlabel('Real #')
title(['Realizations', ', N = ',num2str(Nr)])


% Plot marginal distribution
nexttile(8, [1,2])
dist = counts./Nr;
imagesc(1:n_types, z_vec, dist)
colorbar
title('Marginal distribution')
set(gca, 'xtick', 1:n_types, 'xticklabel', types, 'FontSize',12)
set(gca, 'Colormap', flipud(bone))
xtickangle(90)
ylabel('Depth [m]', 'FontSize',12)

% % Plot marginal distribution
% nexttile(8, [1,2])
% dist = counts./Nr;
% 
% for i_class = 1:n_types
%     color = cmap(i_class, :);
% 
%     for i_z = 1:numel(z_vec)
%         x = [-0.5 0.5 0.5 -0.5] + i_class;
%         if i_z < numel(z_vec)
%             y = [z_vec(i_z) z_vec(i_z) z_vec(i_z+1) z_vec(i_z+1)];
%         else
%             y = [z_vec(i_z) z_vec(i_z) z_vec(i_z)+1 z_vec(i_z)+1];
%         end
%         patch(x, y, interp1([1,0], [color; [1 1 1]], sqrt(dist(i_z, i_class))), 'EdgeColor', 'none');
%     end
% end
% title('Marginal distribution')
% set(gca, 'xtick', 1:n_types, 'xticklabel', types, 'FontSize', 12, 'YDir', 'reverse', 'XLim', [0.5 n_types+0.5])
% xtickangle(90)
% ylabel('Depth [m]', 'FontSize',12)


% Plot entropy
nexttile(10)
plot(E, z_vec, '-k')
set(gca, 'YDir', 'reverse', 'FontSize', 12)
title('Entropy')
xlabel('Entropy', 'FontSize', 12)
xlim([0 1])
ylim([0 max(z_vec)])
ylabel('Depth [m]', 'FontSize', 12)
box off


% Plot number of layers
nexttile(11,[1,2])
histogram('BinCounts', layer_counts, 'BinEdges', edges, 'FaceColor', [0.1 0.1 0.1]);
title('Number of layers')
box off
set(gca, 'FontSize', 12)
xlabel('Number of layers', 'FontSize', 12)
ylabel('Realizations', 'FontSize', 12)


% Plot thickness of layers
nexttile(13, [1,2])
thickness_represented = find(sum(thickness_counts, 2) > 0);
imagesc(1:numel(types), z_vec(thickness_represented), thickness_counts(thickness_represented, :))
title('Layer thicknesses')
set(gca, 'Colormap', flipud(bone))
cb = colorbar;
ylabel(cb, 'Occurences', 'FontSize', 12)
set(gca, 'xtick', 1:n_types, 'xticklabel', types, 'FontSize', 12)
xtickangle(90)
ylabel('Thickness [m]', 'FontSize', 12)

