filename = 'prior_gotaelv_220626_N1000_dmax90_20260622_1044.h5';
addpath data functions
ns = h5read(filename, '/M1');
ms = h5read(filename, '/M2');
z_vec = h5readatt(filename, '/M1', 'x');
Nreals = size(ms, 2);
cmap_lith = h5readatt(filename, '/M2', 'cmap');
n_types = size(cmap_lith, 1);
names = h5readatt(filename, '/M2', 'class_name');


% Plot lithology of the first 100 realizations
figure; clf; set(gcf,'Color','w'); tl = tiledlayout('vertical');
sp(1) = nexttile;
imagesc(1:150, z_vec, ms(:, 1:min([Nreals 150])))
hold on
xlabel('Prior realization number')
ylabel('Depth [m]');
% title('Lithostratigraphy')
colormap(gca, cmap_lith)
clim([0.5 n_types+0.5])
col1 = colorbar;
col1.Ticks = 1:n_types;
col1.TickLabels = string(cellstr(names));
set(col1, 'YDir', 'reverse' );
set(gca, 'FontSize', 14)


% Plot resistivity of the first 100 realizations
sp(2) = nexttile;
imagesc(1:150, z_vec, ns(:, 1:min([Nreals 150])))
hold on
xlabel('Prior realization number')
ylabel('Depth [m]');
% title('Resistivity')
cmap_res = flj_log();
clim([0.1 2600])
col1 = colorbar();
set(col1,'XTick',[0.1 0.3 1 3.2 10 32 100 316 1000 2600]);
set(gca,'Colormap',cmap_res)
title(col1,'Resistivity [\Omegam]','color','k')
set(gca,'ColorScale','log')
set(gca, 'FontSize', 14)


linkprop(sp,{'XLim','YLim'});

exportgraphics(gcf, 'Fig3part2QuickClay.png', 'Resolution', 300)