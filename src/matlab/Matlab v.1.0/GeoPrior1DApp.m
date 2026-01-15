classdef GeoPrior1DApp < matlab.apps.AppBase
    
    % Prior generator app was developed as a part of the INTEGRATE project
    % funded by Innovation Fund Denmark, the UI was further developed to
    % make the functions wider applicable by non-programmers.

    properties (Access = public)
        UIFigure                matlab.ui.Figure
        FilenameLabel           matlab.ui.control.Label
        FilenameTextArea        matlab.ui.control.TextArea
        NLabel                  matlab.ui.control.Label
        NNumericEditField       matlab.ui.control.NumericEditField
        dmaxLabel               matlab.ui.control.Label
        dmaxEditField           matlab.ui.control.NumericEditField
        dzLabel                 matlab.ui.control.Label
        dzEditField             matlab.ui.control.NumericEditField
        ImportButton            matlab.ui.control.Button
        ResistivityButton       matlab.ui.control.Button
        GeneratePriorsButton    matlab.ui.control.Button
        GenerateNPriorsButton   matlab.ui.control.Button
        SummaryButton           matlab.ui.control.Button
        LithAxes                matlab.ui.control.UIAxes
        ResAxes                 matlab.ui.control.UIAxes
        AddClassButton          matlab.ui.control.Button    
        RemoveClassButton       matlab.ui.control.Button
        AddUnitButton           matlab.ui.control.Button
        RemoveUnitButton        matlab.ui.control.Button
        CloseButton             matlab.ui.control.Button
        ClassDataTable          matlab.ui.control.Table
        ExportButton            matlab.ui.control.Button
        UnitDataTable           matlab.ui.control.Table
        WaterTableCheckBox      matlab.ui.control.CheckBox
        WaterTableLabel         matlab.ui.control.Label
        WaterMinField           matlab.ui.control.NumericEditField
        WaterMaxField           matlab.ui.control.NumericEditField
        ColorAssistLabel        matlab.ui.control.Label
        ColorButton             matlab.ui.control.Button
        MergeButton             matlab.ui.control.Button
        HelpButton              matlab.ui.control.Button
        UpClassButton           matlab.ui.control.Button
        DownClassButton         matlab.ui.control.Button
        UpUnitButton            matlab.ui.control.Button    
        DownUnitButton          matlab.ui.control.Button
        MessageLabel            matlab.ui.control.Label
    end
    

    properties (Access = private)
        ClassData
        UnitData
    end


    methods (Access = private)
        
        %% Function the displays the resistivity histograms for the user to inspect
        function ResistivityPushed(app, ~, ~)
            types = app.ClassData(:,1);
            res_means = cell2mat(app.ClassData(:,4));
            res_factor = cell2mat(app.ClassData(:,5));
            % Note on resistivity uncertainty:
            % What is inputted in the App is the factor that matches 3
            % standard deviations in the logarithmic space. Resistivity to
            % reponse signal has exponential relation, and 3 standard
            % deviations covers nearly all possible values (99.7%).
            res_unc = log10(res_factor)/3;


            % Close figure if it already exists to avoid unintended errors
            fig = findobj('Type', 'figure', 'Tag', 'fig_res');
            if ~isempty(fig)
                close(fig);
            end


            % Create new figure
            figure('Tag','fig_res', 'Name', 'Resistivity distributions', 'NumberTitle', 'off'); clf; tl = tiledlayout('flow','TileSpacing','compact'); title(tl,'Resistivity distributions','FontSize',20)
            xs_res=-1:0.01:3.41;
            y_res_total = zeros(size(xs_res));
            for i = 1:numel(types)
                nexttile
                % Calculate what the gaussian curve looks like and plot
                y1_res = normpdf(xs_res, log10(res_means(i)) ,res_unc(i));
                res_plot_improved(10.^xs_res, y1_res)
                y_res_total = y_res_total + y1_res;
                

                % Draw unsaturated resistivity with a red line if relevant
                if size(app.ClassData,2) > 7
                    res_means_unsat = cell2mat(app.ClassData(i,7));
                    res_factor_unsat = cell2mat(app.ClassData(i,8));
                    res_unc_unsat = log10(res_factor_unsat)/3;
                    y2_res=normpdf(xs_res,log10(res_means_unsat), res_unc_unsat);
                    res_plot_improved(10.^xs_res, y2_res)
                    plot(10.^xs_res, y2_res, '-r', 'LineWidth', 1.5)
                    y_res_total = y_res_total + y2_res;
                end

                
                % Plot black line to ensure curve visibile
                plot(10.^xs_res, y1_res, '-k', 'LineWidth', 1.5)
                title(types(i), 'Interpreter', 'none')
                set(gca, 'XTick', [1 10 100 1000], 'XTickLabels', num2str([1 10 100 1000]'))
                set(gca, 'XLim', [1 2600])
            end
            c = colorbar;
            c.Layout.Tile = 'south';
            ylabel(c, 'Resistivity [\Omegam]')
            set(c, 'Ticks', [0.1 1 3 10 30 100 300 1000 3000], 'TickLabels', num2str([0.1 1 3 10 30 100 300 1000 3000]'))
            

            nexttile
            res_plot_improved(10.^xs_res, y_res_total)
            title('Total')
            set(gca, 'XTick', [1 10 100 1000], 'XTickLabels', num2str([1 10 100 1000]'))
            set(gca, 'XLim', [1 2600])


            % Update most recent action
            prevText = app.MessageLabel.Text;
            app.MessageLabel.Text = {prevText{end}, 'Resistivity histograms generated.'};

        end
        
        
        %% Function that generates priors from current settings
        function GeneratePriorsPushed(app, src, event)
            
            % Check for common user errors
            if size(app.ClassData,1) < 2
                    uialert(app.UIFigure, 'Define at least two classes.', 'Wrong input format');
                    return;
            end
            if size(app.UnitData,1) < 2
                    uialert(app.UIFigure, 'Define at least two units.', 'Wrong input format');
                    return;
            end
            for i = 1:size(app.UnitData,1)
                if ~all(ismember(str2num(app.UnitData{i,1}), 1:size(app.ClassData,1)))
                    uialert(app.UIFigure, 'Units with undefined classes.', 'Wrong input format');
                    return;
                end
            end


            % Pack up information in app
            filename = char(app.FilenameTextArea.Value);
            dmax = app.dmaxEditField.Value;
            dz = app.dzEditField.Value;
            if event.Source == app.GeneratePriorsButton
                N = 100;
            elseif event.Source == app.GenerateNPriorsButton
                N = app.NNumericEditField.Value;

                % Delete file to avoid rewriting in old file
                if exist(filename, 'file') == 2
                    delete(filename);
                end

                % Save settings with the correct formatting
                Geology1 = cell2table(app.ClassData(:,[1,2,3,6]),'VariableNames',{'Class', 'Min thickness', 'Max thickness', 'RGB color'});
                Geology2 = cell2table(app.UnitData,'VariableNames',{'Classes','Probabilities','Min no of layers','Max no of layers','Min unit thickness','Max unit thickness','Frequency','Repeat','Min depth'});
                if size(app.ClassData,2) < 7
                    Resistivity = cell2table(app.ClassData(:,[1,4,5]),'VariableNames',{'Class', 'Resistivity', 'Resistivity uncertainty'});
                else
                    Resistivity = cell2table(app.ClassData(:,[1,4,5,7,8]),'VariableNames',{'Class', 'Resistivity', 'Resistivity uncertainty', 'Unsaturated resistivity', 'Unsaturated resistivity uncertainty'});
                end
                writetable(Geology1,filename, 'Sheet', 'Geology1')
                writetable(Geology2,filename, 'Sheet', 'Geology2')
                writetable(Resistivity, filename, 'Sheet', 'Resistivity')
                if app.WaterTableCheckBox.Value
                    WaterTable = table(app.WaterMinField.Value,app.WaterMaxField.Value, 'VariableNames', {'Min depth to water table','Max depth to water table'});
                    writetable(WaterTable,filename,'Sheet','Water table')
                end
            end
            info.filename = filename;
            info.Classes.names = app.ClassData(:,1);
            info.Classes.codes = 1:numel(info.Classes.names);
            info.Classes.min_thick = cell2mat(app.ClassData(:,2));
            info.Classes.max_thick = cell2mat(app.ClassData(:,3)); 
            RGBString = string(app.ClassData(:,6));
            RGBStringArray = split(RGBString,',');
            info.cmaps.Classes = str2double(RGBStringArray)./255;
            info.Resistivity.res = cell2mat(app.ClassData(:,4));
            res_factor = cell2mat(app.ClassData(:,5));
            res_unc = log10(res_factor)/3;
            info.Resistivity.res_unc = res_unc;
            info.Sections.N_sections = numel(app.UnitData(:,1)); 
            info.Sections.types = cellfun(@str2num, app.UnitData(:,1), 'UniformOutput', false);
            info.Sections.probabilities = cellfun(@str2num, app.UnitData(:,2), 'UniformOutput', false);
            

            % Check for more common user errors
            for i = 1:numel(info.Sections.types)
                if i == numel(info.Sections.types)
                    break
                end
                if numel(info.Sections.types{i}) ~= numel(info.Sections.probabilities{i}) && info.Sections.probabilities{i} ~= 1
                    uialert(app.UIFigure, 'Unit classes and probabilities must have the same number of inputs.', 'Wrong input format');
                    return;
                end
                if abs(sum(info.Sections.probabilities{i}) - 1) > 1e-4
                    uialert(app.UIFigure, 'Probabilities must sum to 1.', 'Wrong input format');
                    return;
                end
            end


            % Pack up more information
            info.Sections.min_layers = cell2mat(app.UnitData(1:end-1,3));  
            info.Sections.max_layers = cell2mat(app.UnitData(1:end-1,4)); 
            info.Sections.min_thick = cell2mat(app.UnitData(1:end-1,5)); 
            info.Sections.max_thick = cell2mat(app.UnitData(1:end-1,6)); 
            info.Sections.frequency = cell2mat(app.UnitData(1:end-1,7)); 
            info.Sections.repeat = cell2mat(app.UnitData(1:end-1,8));
            info.Sections.min_depth = cell2mat(app.UnitData(1:end,9)); 
            

            % Check for even more common user errors
            if any(info.Sections.min_layers > info.Sections.max_layers) || any(info.Sections.min_thick > info.Sections.max_thick) || any(info.Classes.min_thick > info.Classes.max_thick)
                    uialert(app.UIFigure, 'Check min-max values.', 'Wrong input format');
                    return;
            end
            if ~all(info.Sections.repeat == 0 | info.Sections.repeat == 1)
                uialert(app.UIFigure, 'Repeat values must be either 1 or 0 (yes or no).', 'Wrong input format');
                return;
            end


            % Pack up information about the water table
            if app.WaterTableCheckBox.Value
                info.Resistivity.unsat_res = cell2mat(app.ClassData(:,7));
                res_factor_unsat = cell2mat(app.ClassData(:,8));
                res_unc_unsat = log10(res_factor_unsat)/3;
                info.Resistivity.unsat_res_unc = res_unc_unsat;
                info.WaterLevel.min = app.WaterMinField.Value;
                info.WaterLevel.max = app.WaterMaxField.Value;
            else
                info.Resistivity.unsat_res = cell2mat(app.ClassData(:,4));
                info.Resistivity.unsat_res_unc = res_unc;
            end
            

            % Send settings to the prior generator
            [priorname,flag_vector] = prior_generator(info, N, dmax, dz, 0);
            

            % Open prior file to explore the prior
            z_vec = h5readatt(priorname, '/M1', 'x');
            cmap = h5readatt(priorname, '/M2', 'cmap');
            types = h5readatt(priorname, '/M2', 'class_name');
            ns = h5read(priorname, '/M1');
            ms = h5read(priorname, '/M2');
            if app.WaterTableCheckBox.Value
                os = h5read(priorname, '/M3');
            end
            n_types = numel(types);
            [Nm, Nr] = size(ms);
            

            % Plot lithology of the first 100 realizations
            imagesc(app.LithAxes, 1:min([Nr 100]), z_vec+dz/2, ms(:,1:min([Nr 100])))
            xlabel(app.LithAxes, 'Real #')
            ylabel(app.LithAxes, 'Depth [m]')
            title(app.LithAxes, 'Lithostratigraphy')
            lith_colorbar = colorbar(app.LithAxes);
            colormap(app.LithAxes,cmap)
            clim(app.LithAxes,[0.5, n_types+0.5])
            lith_colorbar.Ticks = 1:n_types;
            lith_colorbar.TickLabels = types;
            set(lith_colorbar, 'YDir', 'reverse');
            set(app.LithAxes, 'Xlim', [0.5 100.5], 'YLim',[0 dmax])
            if app.WaterTableCheckBox.Value
                hold(app.LithAxes, 'on')
                for i = 1:min([Nr 100])
                    plot(app.LithAxes, [i-0.5, i+0.5], [1,1]*os(i), '-k')
                end
                hold(app.LithAxes,'off')
            end


            % Plot resistivity of the first 100 realizations
            imagesc(app.ResAxes, 1:min([Nr 100]), z_vec+dz/2, ns(:,1:min([Nr 100])))
            xlabel(app.ResAxes, 'Real #')
            ylabel(app.ResAxes, 'Depth [m]')
            title(app.ResAxes, 'Resistivity')
            clim(app.ResAxes, [0.1 2600])
            res_colorbar = colorbar(app.ResAxes);
            colormap(app.ResAxes, flj_log())
            set(res_colorbar, 'Ticks', [0.1 0.3 1 3.2 10 32 100 316 1000 2600], 'TickLabels', num2str([0.1 0.3 1 3.2 10 32 100 316 1000 2600]'));
            ylabel(res_colorbar, 'Resistivity [\Omegam]', 'color', 'k')
            set(app.ResAxes, 'ColorScale', 'log')
            set(app.ResAxes, 'Xlim', [0.5 100.5], 'YLim', [0 dmax])
            if app.WaterTableCheckBox.Value
                hold(app.ResAxes,'on')
                for i = 1:min([Nr 100])
                    plot(app.ResAxes, [i-0.5, i+0.5], [1,1]*os(i), '-k')
                end
                hold(app.ResAxes,'off')
            end
            
            
            % Bad run/settings warnings
            if flag_vector(1) == 1
                uialert(app.UIFigure, 'Contradicting inputs. Consider if layer numbers and thicknesses are reasonably chosen. Generated models likely erroneous.', ...
                    'Prior error (>1000 re-draws)');
            end


            % Prior generator successfully ran
            if N == 100
                app.MessageLabel.Text = {sprintf('%s  created in  %s.', priorname, cd),...
                    sprintf('Average redraws: %.3f',flag_vector(3))};
            else
                app.MessageLabel.Text = {sprintf('%s  created in  %s.', priorname, cd),...
                    sprintf('Settings saved to %s.', string(app.FilenameTextArea.Value)),...
                    sprintf('Average redraws: %.3f',flag_vector(3))};
            end
        end
        
        
        %% Function that adds class to the class table
        function addClass(app, ~, ~)

            selectedRow = app.ClassDataTable.Selection;
            if isempty(app.ClassData)
                app.ClassData = {};
            end
            % Set default values
            if app.WaterTableCheckBox.Value
                newData = {'Class name', [1], [1], [10], [2], sprintf('%0.f,%0.f,%0.f', randi(255,1,3)), [100], [2]};
            else
                newData = {'Class name', [1], [1], [10], [2], sprintf('%0.f,%0.f,%0.f', randi(255,1,3))};
            end
            if isempty(selectedRow)
                app.ClassData = [app.ClassData; newData];
            else
                app.ClassData = [app.ClassData(1:selectedRow, :); newData; app.ClassData(selectedRow+1:end, :)];
            end
            app.ClassDataTable.Data = app.ClassData;

            % Update most recent action
            prevText = app.MessageLabel.Text;
            app.MessageLabel.Text = {prevText{end}, 'Class added to class table.'};
        end


        %% Function that removes class from the class table
        function removeClass(app, ~, ~)
            selectedRow = app.ClassDataTable.Selection;
            if isempty(selectedRow)
                uialert(app.UIFigure, 'Please select a row to delete.', 'No Selection');
                return;
            end

            % Update most recent action
            prevText = app.MessageLabel.Text;
            app.MessageLabel.Text = {prevText{end}, sprintf('%s  removed from class table.', app.ClassDataTable.Data{selectedRow, 1})};

            app.ClassData(selectedRow, :) = [];
            app.ClassDataTable.Data = app.ClassData;
        end
        

        %% Function that adds unit to the unit table
        function addUnit(app, ~, ~)
            selectedRow = app.UnitDataTable.Selection;
            if isempty(app.UnitData)
                app.UnitData = {};
            end
            if isempty(app.ClassData)
                str = '1';
            else
                str = join(string(1:height(app.ClassData)), ',');
            end
            % Set default values
            newData = {char(str), char('1'), [1], [1], [1], [1], [1], [1], [0]};
            if isempty(selectedRow)
                app.UnitData = [app.UnitData; newData];
            else
                app.UnitData = [app.UnitData(1:selectedRow, :); newData; app.UnitData(selectedRow+1:end, :)];
            end
            app.UnitDataTable.Data = app.UnitData;

            % Update most recent action
            prevText = app.MessageLabel.Text;
            app.MessageLabel.Text = {prevText{end}, 'Unit added to unit table.'};
        end

        
        %% Function that removes unit from the unit table
        function removeUnit(app, ~, ~)
            selectedRow = app.UnitDataTable.Selection;
            if isempty(selectedRow)
                uialert(app.UIFigure, 'Please select a row to delete.', 'No Selection');
                return;
            end

            % Update most recent action
            prevText = app.MessageLabel.Text;
            app.MessageLabel.Text = {prevText{end}, 'Unit removed from unit table.'};

            app.UnitData(selectedRow, :) = [];
            app.UnitDataTable.Data = app.UnitData;
           
        end

        
        %% Function to import prior settings from excel sheet
        function ImportData(app, ~, ~)
            [file, path] = uigetfile('*.xlsx', 'Select an Excel File');
            if isequal(file, 0)
                return;
            end
            

            % Construct full file path
            filename = fullfile(path, file);
            [~, filenameOnly, ext] = fileparts(filename);
            app.FilenameTextArea.Value = append(filenameOnly, ext);


            % Open setting with correct formatting
            lithData = readcell(filename, 'Sheet', 'Geology1'); lithData(1, :) = [];
            resData = readcell(filename, 'Sheet', 'Resistivity'); resData(1, :) = [];
            classData = [lithData(:,1:3), resData(:,2:3), lithData(:,4)];
            if any(strcmp('Water table', sheetnames(filename)))
                waterData = readcell(filename, 'Sheet', 'Water table'); waterData(1, :) = [];
                app.WaterTableCheckBox.Value = 1;
                app.WaterTable(app);
                app.WaterMinField.Value = cell2mat(waterData(1));
                app.WaterMaxField.Value = cell2mat(waterData(2));
                classData = [classData,resData(:,4:5)];
            else
                app.WaterTableCheckBox.Value = 0;
                app.WaterTableLabel.Visible = 'off';
                app.WaterMinField.Visible = 'off';
                app.WaterMaxField.Visible = 'off';
            end
            app.ClassData = classData;
            app.ClassDataTable.Data = classData;
            unitData = readcell(filename, 'Sheet', 'Geology2'); unitData(1, :) = [];


            % Recover data, if priors excel file is from version 0.2
            if ismissing(unitData{end,2})
                unitData{end,2} = '1';
            end
            for i = 3:size(unitData,2)
                if ismissing(unitData{end,i})
                    unitData{end,i} = [];
                end
            end
            unitData(1:end, 2) = cellfun(@(x) char(string(x)), unitData(1:end, 2), 'UniformOutput', false);


            % Add columns of 0, if priors excel file is from version 0.2
            if size(unitData, 2) < 9
                unitData(:, end+1) = num2cell(zeros(size(unitData, 1), 1));
            end
            app.UnitData = unitData;
            app.UnitDataTable.Data = unitData;

            % Update most recent action
            prevText = app.MessageLabel.Text;
            app.MessageLabel.Text = {prevText{end}, sprintf('Settings imported from %s.', file)};
        end

        
        %% Function to export prior settings to excel sheet
        function ExportData(app, ~, ~)

            [file, path] = uiputfile('*.xlsx', 'Save Excel File As', string(app.FilenameTextArea.Value));
            if isequal(file, 0)
                return;
            end
            filename = fullfile(path, file);


            % Delete file to avoid rewriting in old file
            if exist(filename, 'file') == 2
                delete(filename);
            end


            [~, filenameOnly, ext] = fileparts(filename);
            app.FilenameTextArea.Value = append(filenameOnly, ext);

            
            % Save settings with the correct formatting
            Geology1 = cell2table(app.ClassData(:,[1,2,3,6]),'VariableNames',{'Class', 'Min thickness', 'Max thickness', 'RGB color'});
            Geology2 = cell2table(app.UnitData,'VariableNames',{'Classes','Probabilities','Min no of layers','Max no of layers','Min unit thickness','Max unit thickness','Frequency','Repeat','Min depth'});
            if size(app.ClassData,2) < 7
                Resistivity = cell2table(app.ClassData(:,[1,4,5]),'VariableNames',{'Class', 'Resistivity', 'Resistivity uncertainty'});
            else
                Resistivity = cell2table(app.ClassData(:,[1,4,5,7,8]),'VariableNames',{'Class', 'Resistivity', 'Resistivity uncertainty', 'Unsaturated resistivity', 'Unsaturated resistivity uncertainty'});
            end
            writetable(Geology1,filename, 'Sheet', 'Geology1')
            writetable(Geology2,filename, 'Sheet', 'Geology2')
            writetable(Resistivity, filename, 'Sheet', 'Resistivity')
            if app.WaterTableCheckBox.Value
                WaterTable = table(app.WaterMinField.Value,app.WaterMaxField.Value, 'VariableNames', {'Min depth to water table','Max depth to water table'});
                writetable(WaterTable,filename,'Sheet','Water table')
            end

            % Update most recent action
            prevText = app.MessageLabel.Text;
            app.MessageLabel.Text = {prevText{end}, sprintf('Settings saved to %s.', file)};
        end

        
        %% Function that updates class data memory if values are changed
        function ClassDataTableCellEdit(app, event)
            app.ClassData = app.ClassDataTable.Data;
            fig = findobj('Type', 'figure', 'Tag', 'fig_res');


            % Update color assistant if color is changed
            if event.Indices(2) == 6
                app.ColorButton.BackgroundColor = str2num(event.NewData)./255;
            end
        

            %% Update resistivity figure if it's already open
            if ~isempty(fig)

                class_changed = event.Indices(1);
                type = app.ClassData(class_changed,1);
                res_mean = cell2mat(app.ClassData(class_changed,4));
                res_factor = cell2mat(app.ClassData(class_changed,5));
                res_unc = log10(res_factor)/3;


                figure(fig)
                nexttile(class_changed)
                cla;
                x=-1:0.01:4;
                y1=normpdf(x, log10(res_mean), res_unc);
                res_plot_improved(10.^x, y1)
                if size(app.ClassData,2) > 7
                    res_mean_unsat = cell2mat(app.ClassData(class_changed,7));
                    res_factor_unsat = cell2mat(app.ClassData(class_changed,8));
                    res_unc_unsat = log10(res_factor_unsat)/3;
                    y2=normpdf(x, log10(res_mean_unsat), res_unc_unsat);
                    res_plot_improved(10.^x, y2)
                    plot(10.^x, y2, '-r', 'LineWidth', 1.5)
                end
                plot(10.^x, y1, '-k', 'LineWidth', 1.5)
                title(type)
                xlabel('Resistivity [\Omegam]')
                set(gca, 'XTick', [0.1 1 10 100 1000], 'XTickLabels', num2str([0.1 1 10 100 1000]'))
            end
        end

        
        %% Function that updates unit data memory if values are changed
        function UnitDataTableCellEdit(app, event)
            app.UnitData = app.UnitDataTable.Data;
        end
        

        %% Funtion that enable water table settings if checkbox is checked
        function WaterTable(app, src, event)

            currentNames = app.ClassDataTable.ColumnName;
            % Add extra data columns
            if app.WaterTableCheckBox.Value
                [nRows, nCols] = size(app.ClassData);
                if nCols < 8
                    for i = 1:nRows
                        app.ClassData{i, nCols+1} = app.ClassData{i,4};
                        app.ClassData{i, nCols+2} = app.ClassData{i,5};
                    end
                end
                if numel(currentNames) < 8
                    currentNames{end+1} = 'Unsaturated res.';
                    currentNames{end+1} = 'Unsaturated res. factor';
                end
                % Make more settings available
                app.ClassDataTable.ColumnName = currentNames;
                app.WaterTableLabel.Visible = 'on';
                app.WaterMinField.Visible = 'on';
                app.WaterMaxField.Visible = 'on';

                % Update most recent action
                prevText = app.MessageLabel.Text;
                app.MessageLabel.Text = {prevText{end}, 'Water table inputs enabled.'};


            % When unchecked, remove the last two columns (if they exist)
            else 
                if numel(currentNames) >= 8
                    currentNames(end-1:end) = [];
                end
                app.ClassDataTable.ColumnName = currentNames;
                [nRows, nCols] = size(app.ClassData);
                if nCols >= 8
                    app.ClassData = app.ClassData(:, 1:nCols-2);
                end
                app.WaterTableLabel.Visible = 'off';
                app.WaterMinField.Visible = 'off';
                app.WaterMaxField.Visible = 'off';

                % Update most recent action
                prevText = app.MessageLabel.Text;
                app.MessageLabel.Text = {prevText{end}, 'Water table inputs disabled.'};
            end
            app.ClassDataTable.Data = app.ClassData;
        end


        %% Function to sum up prior information
        function SummaryPushed(app, src, event)

            [file, path] = uigetfile('*.h5', 'Select an HDF5 File');
            if isequal(file,0)
                return;
            end
            prior_summary(fullfile(path, file),1);

            % Update most recent action
            prevText = app.MessageLabel.Text;
            app.MessageLabel.Text = {prevText{end}, sprintf('Prior summary for  %s  generated.', file)};
        end


        %% Function to open help pdf
        function HelpPushed(app, src, event)
            if isdeployed
                pdfPath = fullfile(ctfroot, 'Manual for prior generator.pdf');
                disp(ctfroot)
                dir(ctfroot)
            else
                pdfPath = 'Manual for prior generator.pdf';
            end
        
            if isfile(pdfPath)
                if ispc
                    winopen(pdfPath);
                elseif ismac
                    system(['open "', pdfPath, '"']);
                else
                    system(['xdg-open "', pdfPath, '"']);
                end
            else
                uialert(app.UIFigure, 'Help file not found.', 'Error');
            end
        end


        %% Function to merge two prior files
        function MergePushed(app, ~, ~)
            % Open new dialogue window
            SchreenSize = get(0, 'ScreenSize');
            w = 400; h = 210;
            dlg = uifigure('Name', 'Merge priors', 'Position', [(SchreenSize(3)-w)/2 (SchreenSize(4)-h)/2 w h]);
            DialogIntroLabel = uilabel(dlg, 'Text', 'Select inputs priors and out prior name:', 'FontSize',13, 'Position', [50 180 330 25]);
            Filename1Field = uieditfield(dlg, 'Position', [50 150 330 25], 'Value', 'prior1.h5', 'Editable', false);
            Filename2Field = uieditfield(dlg, 'Position', [50 120 330 25], 'Value', 'prior2.h5', 'Editable', false);
            GetFile1Button = uibutton(dlg,  'Text', '...', 'Position', [10 150 25 25], 'ButtonPushedFcn', @(src, event) GetFileFunction(Filename1Field));
            GetFile2Button = uibutton(dlg,  'Text', '...', 'Position', [10 120 25 25], 'ButtonPushedFcn', @(src, event) GetFileFunction(Filename2Field));
            OutputName = uitextarea(dlg, 'Position', [50 90 330 25], 'Value', 'output.h5');
            Merge = uibutton(dlg,  'Text', 'Merge!', 'Position', [150 50 100 30], 'ButtonPushedFcn', @(src, event) mergePriors(Filename1Field,Filename2Field,OutputName.Value));
            DoneButton = uibutton(dlg,  'Text', 'Done', 'Position', [150 10 100 30], 'ButtonPushedFcn', @(src, event) closeDialog(dlg));

            
            % Find file locations
            function GetFileFunction(Field)
                [file, path] = uigetfile('*.h5', 'Select an HDF5 File');
                if isequal(file,0)
                    return;
                end
                Field.UserData = fullfile(path, file);
                Field.Tooltip = fullfile(path, file);
                Field.Value = file;
            end

            
            % Pass information to merge prior function
            function mergePriors(Field1, Field2, output_name)
                input_name1 = Field1.UserData;
                if isempty(input_name1)
                    input_name1 = fullfile(pwd, Field1.Value);
                end
                input_name2 = Field2.UserData;
                if isempty(input_name2)
                    input_name2 = fullfile(pwd, Field2.Value);
                end
                
                % Finicky function, so wrapped in 'try'
                try
                    MergePriorH5s(string(input_name1),string(input_name2),string(output_name));

                    % Update most recent action
                    prevText = app.MessageLabel.Text;
                    app.MessageLabel.Text = {prevText{end}, sprintf('%s  and  %s  merged succesfully.', Field1.Value, Field2.Value)};

                catch ME
                    uialert(dlg, ['Error merging priors: ' ME.message], 'Error', 'Icon', 'error');

                    % Update most recent action
                    prevText = app.MessageLabel.Text;
                    app.MessageLabel.Text = {prevText{end}, 'Prior merger failed.'};
                end
            end


            function closeDialog(dlg)
                close(dlg);
            end
        end


        %% Function if color assistant is pushed; a library of colors will show
        function ColorAssistant(app, ~, ~)

            selectedRow = app.ClassDataTable.Selection;
            % Color library for jupiter
            T_jupiter = readtable('jupiter_cyklo_farve_koder.xls');
            T = table(T_jupiter.CODE, T_jupiter.RED, T_jupiter.GREEN, T_jupiter.BLUE, 'VariableNames', {'Name','R','G','B'});
            

            % Open new dialogue window
            SchreenSize = get(0, 'ScreenSize');
            w = 320; h = 320;
            dlg = uifigure('Name', 'Color Assistant', 'Position', [(SchreenSize(3)-w)/2 (SchreenSize(4)-h)/2 w h]);
            previewPanel = uibutton(dlg, 'push', 'Text', '', 'Position', [20 50 280 200], 'BackgroundColor', [1 1 1]);
            lbl = uilabel(dlg, 'Text', 'Select a color:', 'Position', [20 290 280 22]);
            colorDropdown = uidropdown(dlg, 'Items', T.Name, 'Position', [20 260 280 22], 'ValueChangedFcn', @(src, event) updateColorPreview(src, T, previewPanel));
            okButton = uibutton(dlg,  'Text', 'OK', 'Position', [110 10 100 30], 'ButtonPushedFcn', @(src, event) onColorSelected(colorDropdown.Value, T, dlg, app, selectedRow));


            % Change color of color assistant
            function updateColorPreview(dropdown, T, panel)
                idx = find(strcmp(T.Name, dropdown.Value));
                if ~isempty(idx)
                    color = [T.R(idx), T.G(idx), T.B(idx)]./255;
                    panel.BackgroundColor = color;
                end
            end
        
            
            % Input RGB values in data table
            function onColorSelected(selectedName, T, dlg, app, selectedRow)
                idx = find(strcmp(T.Name, selectedName));
                if ~isempty(idx) && ~isempty(selectedRow) 
                    selectedColor = [T.R(idx), T.G(idx), T.B(idx)];
                    classData = app.ClassDataTable.Data;
                    classData{selectedRow, 6} = sprintf('%0.f,%0.f,%0.f', selectedColor);
                    app.ClassDataTable.Data = classData;
                    app.ClassData = classData;
                    app.ColorButton.BackgroundColor = selectedColor./255;
                end
                close(dlg);

                % Update most recent action
                prevText = app.MessageLabel.Text;
                app.MessageLabel.Text = {prevText{end}, sprintf('Color of  %s  updated.', classData{selectedRow, 1})};
            end
        end


        %% Function to move classes up in data table
        function upClass(app, ~, ~)
            selectedRow = app.ClassDataTable.Selection;
            if isempty(selectedRow) || selectedRow == 1
                return;
            end
            app.ClassData([selectedRow-1, selectedRow], :) = app.ClassData([selectedRow, selectedRow-1], :);
            app.ClassDataTable.Data = app.ClassData;

            % Update most recent action
            prevText = app.MessageLabel.Text;
            app.MessageLabel.Text = {prevText{end}, 'Class moved up.'};
        end  

        
        %% Function to move classes down in data table
        function downClass(app, ~, ~)
            selectedRow = app.ClassDataTable.Selection;
            if isempty(selectedRow) || selectedRow == size(app.ClassData,1)
                return;
            end
            app.ClassData([selectedRow, selectedRow+1], :) = app.ClassData([selectedRow+1, selectedRow], :);
            app.ClassDataTable.Data = app.ClassData;

            % Update most recent action
            prevText = app.MessageLabel.Text;
            app.MessageLabel.Text = {prevText{end}, 'Class moved down.'};
        end  


        %% Function to move units up in data table
        function upUnit(app, ~, ~)
            selectedRow = app.UnitDataTable.Selection;
            if isempty(selectedRow) || selectedRow == 1
                return;
            end
            app.UnitData([selectedRow-1, selectedRow], :) = app.UnitData([selectedRow, selectedRow-1], :);
            app.UnitDataTable.Data = app.UnitData;

            % Update most recent action
            prevText = app.MessageLabel.Text;
            app.MessageLabel.Text = {prevText{end}, 'Unit moved up.'};
        end  


        %% Function to move units down in data table
        function downUnit(app, ~, ~)
            selectedRow = app.UnitDataTable.Selection;
            if isempty(selectedRow) || selectedRow == size(app.UnitData,1)
                return;
            end
            app.UnitData([selectedRow, selectedRow+1], :) = app.UnitData([selectedRow+1, selectedRow], :);
            app.UnitDataTable.Data = app.UnitData;

            % Update most recent action
            prevText = app.MessageLabel.Text;
            app.MessageLabel.Text = {prevText{end}, 'Unit moved down.'};
        end
    end
        

    % Setup full application window
    methods (Access = private)
        function createComponents(app)
            screenSize = get(0, 'ScreenSize');
            app.UIFigure = uifigure('Name', 'GeoPrior v1.0','Position', [screenSize(1:2) + 100, screenSize(3:4) - 200]);

            mainGrid = uigridlayout(app.UIFigure, [1,3]);
            mainGrid.ColumnWidth = {'1x','3x','2x'};

                leftPanel = uipanel(mainGrid, 'Title', 'Controls');
                leftGrid = uigridlayout(leftPanel, [8,1], 'RowHeight', {'fit','1x','fit','fit','fit','fit','fit','fit','fit'}, 'Scrollable', 'on', 'Padding', [5 5 5 5]);
        
                    editFieldGrid = uigridlayout(leftGrid, [4, 2], 'ColumnWidth', {'2x', '3x'}, 'RowHeight', {'1x', '1x', '1x', '1x'}, 'Padding', [0 0 0 0]);
                        app.FilenameLabel = uilabel(editFieldGrid, 'Text', 'Settings:', 'FontSize',13);
                        app.FilenameTextArea = uitextarea(editFieldGrid, 'Value', 'prior_apptest.xlsx');
                        app.NLabel = uilabel(editFieldGrid, 'Text', 'No. of models:');
                        app.NNumericEditField = uieditfield(editFieldGrid, 'numeric','Value', 1000);
                        app.dmaxLabel = uilabel(editFieldGrid, 'Text', 'Depth:');
                        app.dmaxEditField = uieditfield(editFieldGrid, 'numeric','Value', 90);
                        app.dzLabel = uilabel(editFieldGrid, 'Text', 'dz:');
                        app.dzEditField = uieditfield(editFieldGrid, 'numeric','Value', 1);
        
                    buttonGrid = uigridlayout(leftGrid, [5, 2]);
                    buttonGrid.ColumnWidth = {'1x', '1x'};
                    buttonGrid.RowHeight = {'1x', '1x', '1x', '1x', '1x'};
                    buttonGrid.Padding = [0 0 0 0];

                        app.ImportButton = uibutton(buttonGrid, 'push', 'Text', 'Open...', 'ButtonPushedFcn', @app.ImportData);
                        app.AddClassButton = uibutton(buttonGrid, 'push', 'Text', 'Add class', 'ButtonPushedFcn', @app.addClass);
                        app.ExportButton = uibutton(buttonGrid, 'push', 'Text', 'Save as...', 'ButtonPushedFcn', @app.ExportData);
                        
                        removeClassGrid = uigridlayout(buttonGrid, [1, 2], 'ColumnWidth', {'3x', '1x'}, 'Padding', [0 0 0 0]);
                            app.RemoveClassButton = uibutton(removeClassGrid, 'push', 'Text', 'Remove class', 'ButtonPushedFcn', @app.removeClass);

                            upDownClassGrid = uigridlayout(removeClassGrid, [2, 1], 'RowHeight', {'1x', '1x'}, 'Padding', [0 0 0 0]);
                                app.UpClassButton = uibutton(upDownClassGrid, 'push', 'Text', '↑', 'ButtonPushedFcn', @app.upClass);
                                app.DownClassButton = uibutton(upDownClassGrid, 'push', 'Text', '↓', 'ButtonPushedFcn', @app.downClass);

                        app.GeneratePriorsButton = uibutton(buttonGrid, 'push', 'Text', {'Generate 100','prior samples'}, 'ButtonPushedFcn', @(src, event) app.GeneratePriorsPushed(src, event));
                        app.ResistivityButton = uibutton(buttonGrid, 'push', 'Text', {'Resistivity','histograms'}, 'ButtonPushedFcn', @app.ResistivityPushed);
                        app.GenerateNPriorsButton = uibutton(buttonGrid, 'push', 'Text', {'Generate N','prior samples','(and save)'}, 'ButtonPushedFcn', @(src, event) app.GeneratePriorsPushed(src, event));
                        app.AddUnitButton = uibutton(buttonGrid, 'push', 'Text', 'Add unit', 'ButtonPushedFcn', @app.addUnit);
                        app.SummaryButton = uibutton(buttonGrid, 'push', 'Text', 'Prior summary', 'ButtonPushedFcn', @app.SummaryPushed);

                        removeUnitGrid = uigridlayout(buttonGrid, [1, 2], 'ColumnWidth', {'3x', '1x'}, 'Padding', [0 0 0 0]);
                            app.RemoveUnitButton = uibutton(removeUnitGrid, 'push', 'Text', 'Remove unit', 'ButtonPushedFcn', @app.removeUnit);
                            
                            upDownUnitGrid = uigridlayout(removeUnitGrid, [2, 1], 'RowHeight', {'1x', '1x'}, 'Padding', [0 0 0 0]);
                                app.UpUnitButton = uibutton(upDownUnitGrid, 'push', 'Text', '↑', 'ButtonPushedFcn', @app.upUnit);
                                app.DownUnitButton = uibutton(upDownUnitGrid, 'push', 'Text', '↓', 'ButtonPushedFcn', @app.downUnit);
                                
                    app.WaterTableCheckBox = uicheckbox(leftGrid, 'Text', 'Add water table', 'ValueChangedFcn', @(src, event) app.WaterTable(src, event));
                    app.WaterTableLabel = uilabel(leftGrid, 'Text', 'Water level (min-max)', 'Visible','off');
                    app.WaterMinField = uieditfield(leftGrid, 'numeric','Value', 0, 'Visible','off');
                    app.WaterMaxField = uieditfield(leftGrid, 'numeric','Value', 10, 'Visible','off');
                    app.ColorAssistLabel = uilabel(leftGrid, 'Text', 'Color assistant');
                    app.ColorButton = uibutton(leftGrid, 'push', 'Text', '', 'BackgroundColor', [1 1 1], 'ButtonPushedFcn', @(src, event) ColorAssistant(app));
                
                        closeGrid = uigridlayout(leftGrid, [1, 2], 'ColumnWidth', {'1x', '1x'}, 'Padding', [0 0 0 0]);
                            app.CloseButton = uibutton(closeGrid, 'push', 'Text', 'Close App', 'ButtonPushedFcn', @(src, event) closeApp(app));
                            % app.HelpButton = uibutton(closeGrid, 'push', 'Text', 'Manual', 'ButtonPushedFcn', @(src, event) HelpPushed(app));
                            app.MergeButton = uibutton(closeGrid, 'push', 'Text', 'Merge priors', 'ButtonPushedFcn', @(src, event) MergePushed(app));
    
                middlePanel = uipanel(mainGrid, 'Title', 'Class and unit data');
                middleGrid = uigridlayout(middlePanel, [3,1], 'RowHeight', {'1x', '1x', 'fit'}, 'Padding', [0 0 0 0]);
                    app.ClassDataTable = uitable(middleGrid, 'Data', {}, 'SelectionType', 'row', 'ColumnEditable', true, 'CellEditCallback', @(src, event)app.ClassDataTableCellEdit(event));
                    app.ClassDataTable.ColumnName = {'Class', 'Min Thickness', 'Max Thickness', 'Resistivity', 'Res. factor', 'RGB'};
                    app.UnitDataTable = uitable(middleGrid, 'Data', {}, 'SelectionType', 'row', 'ColumnEditable', true, 'CellEditCallback', @(src, event)app.UnitDataTableCellEdit(event));
                    app.UnitDataTable.ColumnName = {'Classes','Probabilities','Min # layers','Max # layers','Min thickness','Max thickness','Frequency','Repeat','Min Depth'};
                    app.MessageLabel = uilabel(middleGrid, 'Text', {' ', 'Welcome back!'});

                rightPanel = uipanel(mainGrid, 'Title', 'Visualization');
                rightGrid = uigridlayout(rightPanel, [2,1], 'RowHeight', {'1x','1x'}, 'Padding', [5 5 5 5]);
                    app.LithAxes = uiaxes(rightGrid);
                    app.ResAxes = uiaxes(rightGrid);
        
            app.ClassData = {};
            app.UnitData = {};
        end

    end
    

    methods (Access = public)
        function app = GeoPrior1DApp
            addpath data functions
            createComponents(app);
            registerApp(app, app.UIFigure);
        end
        function closeApp(app,~)
            delete(app.UIFigure);
        end
    end
end
