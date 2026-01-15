function [name, flag_vector] = prior_generator(input, Nreals, dmax, dz, doPlot)

% 1D prior generator for INTEGRATE project
% Written by Jesper Noergaard 07/07/25
%
% Generates an ensemble of prior models from input giving in either an
% excel spreadsheet or from the Prior Generator App
%
%
% Input:
%   input       = Either the name of excel spreadsheet that defines prior
%                   (needs to be in same folder) or a matlab structure
%                   containing the right elements.
%   Nreals      = Number of realizations desired
%   dmax        = Depth of the models
%   dz          = Layer thicknesses of model parameters
%   doPlot      = 1 will display 100 realizations, 0 will not plot anything
%
%
% Output:
%   (A Hdf5 file in the current folder)
%   name        = name of Hdf5 file containing the prior
%   flag_vector = a three element vector containing 1s or 0s depending on
%                   the succes of the operation. First: more the 1000 tries
%                   for a single realization. Second: more the 100 tries
%                   for a single realization. Third: average number of
%                   retries. 
%  
%
% Hdf5 file structure:
%   Group '/' 
%   Dataset 'M1' 
%       Attributes:
%         'is_discrete'
%         'x'
%         'clim'
%         'cmap'
%         'name'
%
%   Dataset 'M2' 
%       Attributes:
%         'is_discrete'
%         'class_name'
%         'class_id'
%         'clim'
%         'cmap'
%         'name'
%
%%% IF WATER TABLE INPUTS %%%
%   Dataset 'M3' 
%       Attributes:
%         'is_discrete'
%         'name'


% Add subfolders with code and data
addpath functions data
warning('off','all')


% Extract input parameters either from Matlab structure or excel filename
if isstruct(input)
    info = input;
    cmaps = info.cmaps;
elseif ischar(input)
    [info,cmaps] = extractPriorInfo(input);
else
    error('First input must be either an excel filename (e.g. ''filename.xlsx'') or a MATLAB structure variable.')
end


% Create z vector and call function that generates priors
z_vec = dz:dz:dmax;
[ms, ns, os, flag_vector] = get_prior_sample(info, z_vec, Nreals);


% Figure out the correct output name
if isstruct(input)
    if endsWith(info.filename, '.xlsx')
        info.filename = info.filename(1:end-5);
    elseif endsWith(info.filename, '.xls')
        info.filename = info.filename(1:end-4);
    end
    name = sprintf('%s_N%d_dmax%d_%s.h5', info.filename, Nreals, dmax, datestr(now,'yyyymmdd_HHMM'));
elseif ischar(input)
    if endsWith(input, '.xlsx')
        input = input(1:end-5);
    elseif endsWith(input, '.xls')
        input = input(1:end-4);
    end
    name = sprintf('%s_N%d_dmax%d_%s.h5', input, Nreals, dmax, datestr(now,'yyyymmdd_HHMM'));
end


% Write to hdf5 file
try;delete(name); end
% Resistivity
h5create(name, '/M1', size(ns'), 'Datatype', 'single')
% h5writeatt(name, '/', 'Creation date', date);
h5write(name, '/M1', ns')
h5writeatt(name, '/M1', 'is_discrete', 0);
h5writeatt(name, '/M1', 'name', 'Resistivity');
h5writeatt(name, '/M1', 'x', 0:dz:dmax-dz); 
h5writeatt(name, '/M1', 'clim', [.1 2600]);
cmap_res = flj_log();
h5writeatt(name, '/M1', 'cmap', cmap_res);


% Lithology
h5create(name,'/M2',size(ms'), 'Datatype', 'int16')
h5write(name,'/M2',ms')
h5writeatt(name,'/M2','is_discrete', 1);
h5writeatt(name,'/M2','name', 'Lithology');
h5writeatt(name,'/M2','class_name', info.Classes.names);
h5writeatt(name,'/M2','class_id', info.Classes.codes);
h5writeatt(name,'/M2','x', 0:dz:dmax-dz); 
h5writeatt(name,'/M2','clim', [0.5 numel(info.Classes.codes)+0.5]);
h5writeatt(name,'/M2','cmap', cmaps.Classes);


% Water table
if isfield(info, 'WaterLevel')
    h5create(name, '/M3',size(os'), 'Datatype', 'single')
    h5write(name, '/M3',os')
    h5writeatt(name, '/M3','is_discrete', 0);
    h5writeatt(name, '/M3','name', 'Waterlevel');
    h5writeatt(name, '/M3','x', 0); 
end


% Write prior settings in hdf5 file
T_geo1 = readtable([info.filename, '.xlsx'], 'Sheet', 'Geology1');
headers_geo1  = string(T_geo1.Properties.VariableNames);
contents_geo1 = string(table2cell(T_geo1));
T_geo2 = readtable([info.filename, '.xlsx'], 'Sheet', 'Geology2');
headers_geo2  = string(T_geo2.Properties.VariableNames);
contents_geo2 = string(table2cell(T_geo2));
T_res = readtable([info.filename, '.xlsx'], 'Sheet', 'Resistivity');
headers_res  = string(T_res.Properties.VariableNames);
contents_res = string(table2cell(T_res));


h5writeatt(name, '/', 'Creation date', date);
h5writeatt(name, '/', 'Class headers', headers_geo1);
h5writeatt(name, '/', 'Class table', contents_geo1);
h5writeatt(name, '/', 'Unit headers', headers_geo2);
h5writeatt(name, '/', 'Unit table', contents_geo2);
h5writeatt(name, '/', 'Resistivity headers', headers_res);
h5writeatt(name, '/', 'Resistivity table', contents_res);

%% Plot figures
if doPlot == 1


% Resistivity distribution so user can check inputs
figure; clf; set(gcf,'Color','w'); tl = tiledlayout('flow','TileSpacing','compact'); title(tl,'Resistivity distributions','FontSize',24)
for i = 1:numel(info.Classes.codes)
    nexttile
    x=-1:0.01:4;
    y1=normpdf(x,log10(info.Resistivity.res(i)),info.Resistivity.res_unc(i)*log10(info.Resistivity.res(i)));
    res_plot_improved(10.^x,y1)
    if isfield(info,'WaterLevel')
        y2=normpdf(x,log10(info.Resistivity.unsat_res(i)),info.Resistivity.unsat_res_unc(i)*log10(info.Resistivity.unsat_res(i)));
        res_plot_improved(10.^x,y2)
        plot(10.^x,y2,'-r','LineWidth',1.5)
    end
    plot(10.^x,y1,'-k','LineWidth',1.5)
    title(info.Classes.names(i))
    xlabel('Resistivity [\Omegam]')
    set(gca,'XTick',[0.1 1 10 100 1000],'XTickLabels',num2str([0.1 1 10 100 1000]'))
end
c = colorbar;
c.Layout.Tile = 'south';
set(c,'Ticks',[0.1 1 3.2 10 32 100 320 1000 3200],'TickLabels',num2str([0.1 1 3.2 10 32 100 320 1000 3200]'))


% Plot lithology of the first 100 realizations
figure; clf; set(gcf,'Color','w'); tl = tiledlayout('vertical'); title(tl,'Prior realizations','FontSize',24);
sp(1) = nexttile;
imagesc(1:100,z_vec,ms(1:min([Nreals 100]),:)')
hold on
xlabel('Real #')
ylabel('depth [m]');
title('Lithostratigraphy')
colormap(gca,cmaps.Classes)
clim([0.5 numel(info.Classes.codes)+0.5])
col1 = colorbar;
col1.Ticks = info.Classes.codes;
col1.TickLabels = info.Classes.names;
set(col1, 'YDir', 'reverse' );
if isfield(info,'WaterLevel')
    for i = 1:min([Nreals 100])
        plot([i-0.5, i+0.5],[1,1]*os(i),'-k')
    end
end


% Plot resistivity of the first 100 realizations
sp(2) = nexttile;
imagesc(1:100,z_vec,ns(1:min([Nreals 100]),:)')
hold on
xlabel('Real #')
ylabel('depth [m]');
title('Resistivity')
cmap_res = flj_log();
clim([0.1 2600])
col1 = colorbar();
set(col1,'XTick',[0.1 0.3 1 3.2 10 32 100 316 1000 2600]);
set(gca,'Colormap',cmap_res)
title(col1,'Resistivity [\Omegam]','color','k')
set(gca,'ColorScale','log')
if isfield(info,'WaterLevel')
    for i = 1:min([Nreals 100])
        plot([i-0.5, i+0.5],[1,1]*os(i),'-k')
    end
end


linkprop(sp,{'XLim','YLim'});

warning('on','all')
end

