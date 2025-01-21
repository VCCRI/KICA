% CLASS DESCRIPTION 
%
% NOTES:
%
% RELEASE VERSION: 0.6
%
% AUTHORS: Satya Arjunan (s.arjunan@victorchang.edu.au)
%          Anton Shpak (a.shpak@victorchang.edu.au)
%
% DATE: February 2020
classdef FileWriter < handle
    
    properties (Constant, Access = private)
        
        FolderName_Figures = "Figures";
        
        FolderName_AnalysisAndQC_Suffix = "_Analysis_and_QC";

        FileName_CellID_Suffix = "_CellID_";
        FileName_FigurePulseDetection_Prefix = "";
        FileName_FigurePulseDetection_Suffix = "_Pulse_Detection";

        FileName_FigurePulseAnalysis_Prefix = "";
        FileName_FigurePulseAnalysis_Suffix = "_Pulse_Analysis";
       
        FileName_QCReport_Prefix = "";
        FileName_QCReport_Suffix = "_Analysis_and_QC";
        
        
        WorksheetNumber_CellsPassedQC = 1;
        WorksheetNumber_CellsPassedQCStatsAll = 2;
        WorksheetNumber_CellsPassedQCStatsPaced = 3;
        WorksheetNumber_CellsPassedQCData = 4;
        WorksheetNumber_CellsFailedQC = 5;
        WorksheetName_CellsPassedQC = "QC Passed Pulses";
        WorksheetName_CellsPassedQCStatsAll = "QC Passed Stats (All)";
        WorksheetName_CellsPassedQCStatsPaced = "QC Passed Stats (Paced)";
        WorksheetName_CellsPassedQCData = "QC Passed Data";
        WorksheetName_CellsFailedQC = "QC Failed Pulses";

        FigureInQCReportFileRowSpan = 20;
        RowSpanBetweenTables = 2;
        
    end
    
    properties (Access = private)
        well = Well.empty;
        
        folderName_AnalysisAndQC = "";
        folderName_Figures = "";
        fileName_QCReport = "";
        
        cellsPassedQC;
        cellsFailedQC;
        
        startIndexesForFiguresPassedQC;
        startIndexesForFiguresFailedQC;
        pulseTablesPassedQC;
        
        e;      % Excel ActiveX server
        ewb;    % Excel Workbook
    end
    
    methods
        function obj = FileWriter(well)
            obj.well = well;
            
            obj.cellsPassedQC = findobj(obj.well.Cells, 'QCStatus', 1); 
            obj.cellsFailedQC = findobj(obj.well.Cells, '-not', 'QCStatus', 1);

            obj.InitFoldersAndFiles();
        end

        function WriteWellAnalysisResults(self)

            if (Parameters.QC.IsQCRequired)
                self.WriteQCResultsToFile();
            end

            if (Parameters.Visualization.SaveVisualizedCellsToFiles)
                self.SaveCellsFiguresToFiles();
            end
        end

    end
    
    methods (Access = private)
        
        function InitFoldersAndFiles(self)

            self.folderName_AnalysisAndQC = fullfile(self.well.FilePath, strcat(self.well.FileName, FileWriter.FolderName_AnalysisAndQC_Suffix));
            if (~exist(self.folderName_AnalysisAndQC, 'dir'))
                mkdir(self.folderName_AnalysisAndQC)
            end

            self.folderName_Figures = fullfile(self.folderName_AnalysisAndQC, FileWriter.FolderName_Figures);
            if (Parameters.Visualization.SaveVisualizedCellsToFiles)
                if (~exist(self.folderName_Figures, 'dir'))
                    mkdir(self.folderName_Figures)
                end
            end
            
            self.fileName_QCReport = fullfile(self.folderName_AnalysisAndQC, strcat(FileWriter.FileName_QCReport_Prefix, self.well.FileName, FileWriter.FileName_QCReport_Suffix, '.xlsx'));
            self.fileName_QCReport = FileWriter.CorrectFileName(self.fileName_QCReport);
            if (exist(self.fileName_QCReport, 'file'))
                delete(self.fileName_QCReport);
            end
            
        end
        
    end
    
    
    
	methods (Access = private)
        
        function WriteQCResultsToFile(self)
            
            %'WriteVariableNames', 'false'
           
            try
                startWriteToFile = Log.StartBlock(1, strcat("Started writing to file '", self.fileName_QCReport, "'"));
                
                % write cells that passed QC
                [self.startIndexesForFiguresPassedQC, self.pulseTablesPassedQC] = self.WriteCellsAndPulsesInfoToQCReport(self.cellsPassedQC,...
                                                                                             FileWriter.WorksheetNumber_CellsPassedQC);

                % write statistics of all cells that passed QC
                self.WriteCellsAndPulsesStats(self.pulseTablesPassedQC, FileWriter.WorksheetNumber_CellsPassedQCStatsAll, 0);

                % write statistics of paced cells that passed QC
                self.WriteCellsAndPulsesStats(self.pulseTablesPassedQC, FileWriter.WorksheetNumber_CellsPassedQCStatsPaced, 1);

                % write data of cells that passed QC
                self.WriteCellsAndPulsesData(self.cellsPassedQC, FileWriter.WorksheetNumber_CellsPassedQCData);

                % write cells that not passed QC
                self.startIndexesForFiguresFailedQC = self.WriteCellsAndPulsesInfoToQCReport(self.cellsFailedQC, FileWriter.WorksheetNumber_CellsFailedQC);
                
                % write figures to the report file
                self.WriteFiguresToQCReport();
                
                Log.EndBlock(startWriteToFile, 1, strcat("Finished writing to file '", self.fileName_QCReport, "'"));

            catch ME
                Log.ErrorMessage(1, strcat("Failed to write to file '", self.fileName_QCReport, "'"));
                
                ex = MException(Error.ID_WriteFileError, strcat(Error.Msg_WriteFileError, '\r', ME.identifier, "\r", ME.message));
                throw(ex);
            end
        end
        
        
        function [startIndexesForFigures, pulseTables] = WriteCellsAndPulsesInfoToQCReport(self, cells, sheetNumber)

            % initialise empty table to be returned if no QC Passed cells
            pulseTables = [];
            startIndexesForFigures = zeros(length(cells), 1);
            startIndex = 1;

            % write file info
            startWriteFileInfo = Log.StartBlock(2, strcat("Start writing File info in worksheet ", num2str(sheetNumber)));
            tableFile_VarNames = {'File_Name'};
            tableFile = table(strcat(self.well.FileName, self.well.FileExt), 'VariableNames', tableFile_VarNames);
            writetable(tableFile, self.fileName_QCReport, 'FileType', 'spreadsheet', 'Sheet', sheetNumber, 'Range', strcat('A', num2str(startIndex)));
            startIndex = startIndex + size(tableFile, 1) + FileWriter.RowSpanBetweenTables + 1;
            Log.EndBlock(startWriteFileInfo, 2, strcat("Finished writing File info in worksheet ", num2str(sheetNumber)), 1);


            % write user parameter info
            startWriteParamInfo = Log.StartBlock(2, strcat("Start writing user parameter info in worksheet ", num2str(sheetNumber)));
            tableParam_VarNames = {'Parameter', 'Value'};
            
            params = ["pulseDetection_signalType",...
                "stimuliPeriod_ms",...
                "stimuliNumber",...
                "stimulationStart_ms",...
                "stimulusPulseDuration_ms",...
                "pulseDetection_thresholdPercentage",...
                "pulseDetection_numberOfSecondsAtStartToIgnore",...
                "pulseDetection_removeFalsePulses_PeakThresholdPercentage",...
                "pulseDetection_removeFalsePulses_DurationThresholdPercentage",...
                "pulseDetection_denoise_waveletName",...
                "pulseDetection_denoise_waveletNumber",...
                "pulseDetection_denoise_waveletThresholdRule",...
                "pulseAnalysis_apDurations",...
                "pulseAnalysis_apdIsEndPointApproximatedSymbol",...
                "pulseAnalysis_pulseStartOnStimulusDetectionDelta_ms",...
                "pulseAnalysis_pulseStartOnStimulusDetectionSymbol",...
                "pulseAnalysis_pulseStartPointType",...
                "visualize_showVisualizedCells",...
                "visualize_saveVisualizedCellsToFiles",...
                "qc_isQC_Required",...
                "qc_SNR_Threshold",...
                "qc_writeFiguresToQCReportFile",...
                "qc_checkForSNR",...
                "qc_checkForNoPulsesDetected",...
                "qc_checkForPulsesMissingStimuli",...
                "qc_checkForPulsesSpanMoreThanOneStimulus"]';
            tableParam = table(params,...
                [strcat("SignalType.", string(Parameters.PulseDetection.SignalType)),...
                 num2str(Stimulation.StimuliPeriod_ms),...
                 num2str(Stimulation.StimuliNumber),...
                 num2str(Stimulation.StimulationStart_ms),...
                 num2str(Stimulation.StimulusPulseDuration_ms),...
                 string(Parameters.PulseDetection.ThresholdPercentage),...
                 string(Parameters.PulseDetection.NumberOfSecondsAtStartToIgnore),...
                 string(Parameters.PulseDetection.RemoveFalsePulses_PeakThresholdPercentage),...
                 string(Parameters.PulseDetection.RemoveFalsePulses_DurationThresholdPercentage),...
                 strcat("""", string(Parameters.PulseDetection.Denoise_WaveletName), """"),...
                 string(Parameters.PulseDetection.Denoise_WaveletNumber),...
                 strcat("""", string(Parameters.PulseDetection.Denoise_WaveletThresholdRule), """"),...
                 strcat('[', num2str(Parameters.PulseAnalysis.APDs), ']'),...
                 strcat("""", string(Parameters.PulseAnalysis.APDIsEndPointApproximatedSymbol), """"),...
                 string(Parameters.PulseAnalysis.PulseStartOnStimulusDetectionDelta_ms),...
                 strcat("""", string(Parameters.PulseAnalysis.PulseStartOnStimulusDetectionSymbol), """"),...
                 strcat("PulseStartPointType.", string(Parameters.PulseAnalysis.PulseStartPointType)),...
                 string(Parameters.Visualization.ShowVisualizedCells),...
                 string(Parameters.Visualization.SaveVisualizedCellsToFiles),...
                 string(Parameters.QC.IsQCRequired),...
                 string(Parameters.QC.SNR_Threshold),...
                 string(Parameters.QC.WriteFiguresToQCReportFile),...
                 string(Parameters.QC.CheckForSNR),...
                 string(Parameters.QC.CheckForNoPulsesDetected),...
                 string(Parameters.QC.CheckForPulsesMissingStimuli),...
                 string(Parameters.QC.CheckForPulsesSpanMoreThanOneStimulus)]',...
                 'VariableNames', tableParam_VarNames);
            writetable(tableParam, self.fileName_QCReport, 'FileType','spreadsheet', 'Sheet', sheetNumber, 'Range', strcat('A', num2str(startIndex)));
            startIndex = startIndex + size(tableParam, 1) + FileWriter.RowSpanBetweenTables + 1;
            Log.EndBlock(startWriteParamInfo, 2, strcat("Finished writing user parameter info in worksheet ", num2str(sheetNumber)), 1);

            % write well info
            startWriteWellInfo = Log.StartBlock(2, strcat("Start writing Well info in worksheet ", num2str(sheetNumber)));
            tableWell_VarNames = {'Well_Date', 'Well_Description'};
            tableWell = table(self.well.Date, self.well.Description, 'VariableNames', tableWell_VarNames);
            writetable(tableWell, self.fileName_QCReport, 'FileType','spreadsheet', 'Sheet', sheetNumber, 'Range', strcat('A', num2str(startIndex)));
            startIndex = startIndex + size(tableWell, 1) + FileWriter.RowSpanBetweenTables + 1;
            Log.EndBlock(startWriteWellInfo, 2, strcat("Finished writing Well info in worksheet ", num2str(sheetNumber)), 1);
            
            if (isempty(cells))

                % write cells info
                startWriteCellsInfo = Log.StartBlock(2, strcat("Start writing Cells summary info in worksheet ", num2str(sheetNumber)));
                tableCells = table("No Cells here");
                writetable(tableCells, self.fileName_QCReport, 'FileType','spreadsheet', 'Sheet', sheetNumber, 'Range', strcat('A', num2str(startIndex)), 'WriteVariableNames', 0);
                Log.EndBlock(startWriteCellsInfo, 2, strcat("Finished writing Cells summary info in worksheet ", num2str(sheetNumber)), 1);
                
            else
                % write cells info
                startWriteCellsInfo = Log.StartBlock(2, strcat("Start writing Cells summary info in worksheet ", num2str(sheetNumber)));
                tableCells_VarNames = {'Cell_ID', 'Cell_SNR', 'Cell_QCStatus', 'Cell_QCStatus_String'};
                %variableTypes = {'double', 'double', 'uint32', 'string'};
                tableCells = table([cells.ID]', [cells.SNR2]',...
                                   [cells.QCStatus]', [cells.QCStatusString]',...
                                   'VariableNames', tableCells_VarNames);
                writetable(tableCells, self.fileName_QCReport, 'FileType','spreadsheet', 'Sheet', sheetNumber, 'Range', strcat('A', num2str(startIndex)));
                startIndex = startIndex + size(tableCells, 1) + FileWriter.RowSpanBetweenTables;
                Log.EndBlock(startWriteCellsInfo, 2, strcat("Finished writing Cells summary info in worksheet ", num2str(sheetNumber)), 1);
                

                % write pulses info for each cell 
                startWriteAllCells = Log.StartBlock(2, strcat("Start writing Cells Pulses for ", num2str(length(cells)), " cells in worksheet ", num2str(sheetNumber)));

                % define columns names
                apdsNames = Parameters.PulseAnalysis.APDs;
                columnNames = horzcat({'Cell_ID', 'Pulse_ID', 'Pulse_Start_ms','PulseStartOnStimulus', 'Pulse_End_ms', 'Pulse_Duration_ms', 'Pulse_Start_On_Stim'},...
                                      cellstr(strcat("APD_", string(apdsNames), "_ms")), cellstr(strcat("APD_", string(apdsNames), "_EndPointApproximated")), {'APD_30_90'},...
                                      {'Pulse_ActivationPointTime_ms', 'Pulse_UpstrokeStartTime_ms', 'Pulse_UpstrokeEndTime_ms', 'Pulse_UpstrokeRiseTime_ms',...
                                        'Pulse_UpstrokeValue', 'Pulse_MaxValue', 'Pulse_UpstrokeVelocity', 'Pulse_MaxUpstrokeVelocityTime_ms', 'Pulse_MaxUpstrokeVelocityValue'});
                calcium_columnNames = horzcat({'Pulse_RiseTime_10_90_ms', 'RiseStartApproximated', 'RiseEndApproximated',...
                                               'Pulse_FallTime_90_10_ms', 'FallStartApproximated', 'FallEndApproximated'});
                
                figureRowSpan = 0;
                if (Parameters.QC.WriteFiguresToQCReportFile)
                    figureRowSpan = FileWriter.FigureInQCReportFileRowSpan;
                end
                
                startIndexCellsSummaryTable = startIndex;
                for i = 1 : length(cells)
                    currentCell = cells(i);
                    pulses = currentCell.Pulses;
                    % number of rows for the current cell
                    numberOfPulses = length(currentCell.Pulses);

                    if (numberOfPulses > 0)
                        % represent APDs as a set of columns
                        apds = [pulses.APDs]';
                        apdDurations = num2cell(reshape([apds.Duration_ms], size(apds)), 1);
                        isEndPointApproximated = string(reshape([apds.IsEndPointApproximated], size(apds)));
                        isEndPointApproximated = num2cell(isEndPointApproximated, 1);
                        upstroke = [pulses.Upstroke]';
                        pulseUpstrokeEnsembleMaxPoint = [pulses.UpstrokePeakPoint]';
                        pulseTables{i} = table([pulses.CellID]', [pulses.ID]', [pulses.StartTime_ms]', string([pulses.IsPulseStartOnStimulus]'), [pulses.EndTime_ms]', [pulses.Duration_ms]',...
                                            [pulses.PulseStartOnStimulusNumber]', apdDurations{:}, isEndPointApproximated{:}, [pulses.APD_30_90_Ratio]', [pulses.ActivationPointTime_ms]',...
                                            [upstroke.StartTime_ms]', [upstroke.PeakTime_ms]', [upstroke.RiseTime_ms]', [upstroke.PeakValue]', [pulseUpstrokeEnsembleMaxPoint.Value]',...
                                            [upstroke.Velocity]', [upstroke.MaxVelocityTime_ms]', [upstroke.MaxVelocityValue]', 'VariableNames', columnNames);

                        if (Parameters.PulseDetection.SignalType == SignalType.Calcium)
                            rise_10_90 = [pulses.Rise_10_90]';
                            fall_90_10 = [pulses.Fall_90_10]';
                            tableRiseFall = table([rise_10_90.Duration_ms]', string([rise_10_90.IsStartPointApproximated]'), string([rise_10_90.IsEndPointApproximated]'),...
                                                  [fall_90_10.Duration_ms]', string([fall_90_10.IsStartPointApproximated]'), string([fall_90_10.IsEndPointApproximated]'),...
                                                  'VariableNames', calcium_columnNames);
                            pulseTables{i} = [pulseTables{i}, tableRiseFall];
                        end
                        % remove 'false' flags from the table to visualise 'true' flags easily
                        for j=1:length(pulseTables{i}.Properties.VariableNames)
                            if isa(pulseTables{i}{:,j}, 'string')
                                pulseTables{i}{:,j}(pulseTables{i}{:,j} == 'false') = '';
                            end
                        end
                    else
                        % insert header and current cell ID if the cell generated no pulse
                        NAs = num2cell(repmat({' '}, 1, size(columnNames, 2) - 1), 1);
                        pulseTables{i} = table(currentCell.ID, NAs{:}, 'VariableNames', columnNames);
                    end
                    % write current cell pulses info
                    writetable(pulseTables{i}, self.fileName_QCReport, 'FileType', 'spreadsheet', 'Sheet', sheetNumber, 'Range', strcat('A', num2str(startIndexCellsSummaryTable)));
                    startIndexesForFigures(i) = startIndexCellsSummaryTable + numberOfPulses + 2;
                    startIndexCellsSummaryTable = startIndexCellsSummaryTable + numberOfPulses + (figureRowSpan + 2) + FileWriter.RowSpanBetweenTables;
                end
                Log.EndBlock(startWriteAllCells, 2, strcat("Finished writing All Cells Pulses in worksheet ", num2str(sheetNumber)));
            end
        end

        function WriteCellsAndPulsesStats(self, pulseTables, sheetNumber, isPaced)

            startIndex = 1;
            if (length(pulseTables) > 0)
                % write pulse statistics for each cell 
                startWriteAllCells = Log.StartBlock(2, strcat("Start writing Cells pulses statistics for ", num2str(length(pulseTables)), " cells in worksheet ", num2str(sheetNumber)));

                startIndexCellsSummaryTable = startIndex;
                for i = 1 : length(pulseTables)
                    currentTable = pulseTables{i};
                    % if isPaced, keep only rows with pulses that started on stimulus
                    if (isPaced == 1)
                        currentTable(~ismember(currentTable.PulseStartOnStimulus, 'true'), :) = [];
                    end
                    if (height(currentTable) > 0)
                        apdsNames = Parameters.PulseAnalysis.APDs;
                        activationPointIntervals = currentTable.Pulse_ActivationPointTime_ms - circshift(currentTable.Pulse_ActivationPointTime_ms, 1);
                        % remove the first element if the length of activation point intervals > 1
                        if (length(activationPointIntervals) > 1)
                          activationPointIntervals = activationPointIntervals(2:end);
                        end
                        removeCols = {'Pulse_ID', 'Pulse_Start_ms','PulseStartOnStimulus', 'Pulse_End_ms', 'Pulse_Start_On_Stim',...
                                       'Pulse_UpstrokeStartTime_ms',...
                                       'Pulse_UpstrokeEndTime_ms','Pulse_ActivationPointTime_ms', 'Pulse_MaxUpstrokeVelocityTime_ms'};
                        removeCols =  [removeCols, cellstr(strcat('APD_', string(apdsNames), '_EndPointApproximated'))];
                        if (Parameters.PulseDetection.SignalType == SignalType.Calcium)
                            removeCols =  [removeCols, {'RiseStartApproximated', 'RiseEndApproximated', 'FallStartApproximated', 'FallEndApproximated'}];
                        end
                        currentTable = removevars(currentTable, removeCols');
                        % write current cell statistics
                        means = varfun(@mean, currentTable, 'InputVariables', @isnumeric);
                        stds = varfun(@std, currentTable, 'InputVariables', @isnumeric);
                        Ns = varfun(@length, currentTable, 'InputVariables', @isnumeric);
                        get_SEM = @(x) std(x)/sqrt(length(x));
                        SEMs = varfun(get_SEM, currentTable, 'InputVariables', @isnumeric);
                        Ns.Properties.VariableNames = currentTable.Properties.VariableNames;
                        means.Properties.VariableNames = currentTable.Properties.VariableNames;
                        stds.Properties.VariableNames = currentTable.Properties.VariableNames;
                        SEMs.Properties.VariableNames = currentTable.Properties.VariableNames;
                        % add a new column with cell ID and row names
                        rowNames = ["N", "Average", "STDEV", "SEM"]';
                        newCol = table(rowNames, 'VariableNames', {strcat('Cell_ID_', num2str(currentTable.Cell_ID(1)))});
                        statsTable = [Ns; means; stds; SEMs];
                        statsTable = [newCol, statsTable];
                        % add a new column for ActivationPointInterval_ms
                        rows = [length(activationPointIntervals), mean(activationPointIntervals), std(activationPointIntervals), get_SEM(activationPointIntervals)]';
                        newCol = table(rows, 'VariableNames', {'ActivationPointInterval_ms'});
                        statsTable = [statsTable, newCol];
                        % drop Cell ID column
                        statsTable = removevars(statsTable, {'Cell_ID'});
                        rowSize = height(statsTable);
                        %rowSize = height(currentTable);
                        %writetable(currentTable, self.fileName_QCReport, 'FileType', 'spreadsheet', 'Sheet', sheetNumber, 'Range', strcat('A', num2str(startIndexCellsSummaryTable)));
                        writetable(statsTable, self.fileName_QCReport, 'FileType', 'spreadsheet', 'Sheet', sheetNumber, 'Range', strcat('A', num2str(startIndexCellsSummaryTable)));
                        startIndexCellsSummaryTable = startIndexCellsSummaryTable + rowSize + FileWriter.RowSpanBetweenTables + 1;
                    end
                end
                Log.EndBlock(startWriteAllCells, 2, strcat("Finished writing Cells pulses statistics in worksheet ", num2str(sheetNumber)));
            end
        end

        function WriteCellsAndPulsesData(self, cells, sheetNumber)
            startIndex = 1;
            if (~isempty(cells))
                % write cell data
                startWriteAllCells = Log.StartBlock(2, strcat("Start writing Cells data for ", num2str(length(cells)), " cells in worksheet ", num2str(sheetNumber)));

                % define columns names
                apdsNames = Parameters.PulseAnalysis.APDs;
                tableData = table(cells(1).Times, 'VariableNames', {'Raw baseline corrected: Time (msec)'});
                for i = 1 : length(cells)
                    currentCell = cells(i);
                    tableData = [tableData, table(currentCell.RawBaselineCorrected, 'VariableNames', {strcat('Cell_ID_', num2str(currentCell.ID))})];
                end
                writetable(tableData, self.fileName_QCReport, 'FileType', 'spreadsheet', 'Sheet', sheetNumber, 'Range', strcat('A', num2str(startIndex)));
                Log.EndBlock(startWriteAllCells, 2, strcat("Finished writing Cells data in worksheet ", num2str(sheetNumber)));
            end
        end
        
        function WriteFiguresToQCReport(self)
            
            startWriteFiguresToFile = Log.StartBlock(2, strcat("Started writing figures to the report file"));

            try
                startOpenExcel = Log.StartBlock(3, strcat("Started opening Excel ActiveX"));
                self.OpenExcel();
                Log.EndBlock(startOpenExcel, 3, strcat("Finished opening Excel ActiveX"));

                worksheetCellsPassedQC = self.ewb.Worksheets.Item(FileWriter.WorksheetNumber_CellsPassedQC);
                worksheetCellsFailedQC = self.ewb.Worksheets.Item(FileWriter.WorksheetNumber_CellsFailedQC);                
                
                % write figures
                if (Parameters.QC.WriteFiguresToQCReportFile)

                    % write figures for cells passed QC
                    worksheetCellsPassedQC.Activate();
                    self.WriteFiguresToWorksheet(self.startIndexesForFiguresPassedQC, self.cellsPassedQC, worksheetCellsPassedQC);

                    % write figures for cells not passed QC
                    worksheetCellsFailedQC.Activate();
                    self.WriteFiguresToWorksheet(self.startIndexesForFiguresFailedQC, self.cellsFailedQC, worksheetCellsFailedQC);

                end

                % rename worksheets in the QCReport file
                self.RenameWorkheetsInQCReport();

                % goto beginning of the worksheet
                self.e.Goto(get(worksheetCellsFailedQC, 'Range', 'A1', 'A1'), true);
                self.e.Goto(get(worksheetCellsPassedQC, 'Range', 'A1', 'A1'), true);

                % save file
                self.ewb.Save; 

                startClosingExcel = Log.StartBlock(3, strcat("Started closing Excel ActiveX"));
                self.CloseExcel();
                Log.EndBlock(startClosingExcel, 3, strcat("Finished closing Excel ActiveX"));

            catch ME
                self.CloseExcel();

                Log.ErrorMessage(1, strcat("Failed writing figures to the report file"));

                ex = MException(Error.ID_WriteFileError, strcat(Error.Msg_WriteFifuresToFileError, '\r', ME.identifier, "\r", ME.message));
                throw(ex);

            end

            Log.EndBlock(startWriteFiguresToFile, 2, strcat("Finished writing figures to the report file"));
        end
        
        function WriteFiguresToWorksheet(self, startIndexesForFigures, cells, worksheet)
            
            for i = 1 : length(cells)

                currentCell = cells(i);
                
                startWriteFigureToReportFile = Log.StartBlock(3, strcat("Started writing figures for CellID: ", num2str(currentCell.ID), " to report file"));

                rangeStartIndex = startIndexesForFigures(i);
                rangeEndIndex = rangeStartIndex + FileWriter.FigureInQCReportFileRowSpan;
                
                % Pulse Detection figure
                % obtain the figure
                figurePulseDetection = currentCell.GetFigurePulseDetection();

                % save the figure as png
                startSavePngFigure = Log.StartBlock(4, strcat("Started saving png figure for CellID: ", num2str(currentCell.ID), " Pulse Detection"));
                filename = self.GetFileNameFigurePulsesDetection(currentCell, '.png');
                hLegend = findobj(figurePulseDetection, 'Type', 'Legend');
                set(hLegend, 'Visible', 'off');
                exportgraphics(figurePulseDetection, filename, 'Resolution', 100);
                set(hLegend, 'Visible', 'on');
                Log.EndBlock(startSavePngFigure, 4, strcat("Finished saving png figure for CellID: ", num2str(currentCell.ID), " Pulse Detection"));

                % copy to clipboard
                %FigureUtils.CopyFigureToClipboard(figurePulseDetection);
                
                % insert figure to worksheet
                figure1RangeColumn = 'A';
                worksheetRange = get(worksheet, 'Range', strcat(figure1RangeColumn, num2str(rangeStartIndex)),...
                                                         strcat(figure1RangeColumn, num2str(rangeEndIndex-1)));
                                                     
                startAddPngFigure = Log.StartBlock(4, strcat("Started inserting png figure for CellID: ", num2str(currentCell.ID), " Pulse Detection"));
                % method 1: use AddPicture to insert png into xlsx file (works with parallelisation)
                Shapes = worksheet.Shapes;
                Shapes.AddPicture(strrep(filename, '/', '\'), 0, 1, worksheetRange.Left, worksheetRange.Top, -1, -1);
                Shapes.Item(Shapes.Count).LockAspectRatio = 'msoTrue';
                Shapes.Item(Shapes.Count).Height = worksheetRange.Height;

                % method 2: use clipboard to paste image into xlsx file (doesn't work with parallelisation)
                %worksheetRange.PasteSpecial();
                %self.e.Selection.ShapeRange.Item(1).Height = worksheetRange.Height;
                % method 3: use Insert to insert png into xlsx file (works with parallelisation but having issues with saving and reading file)
                %picture = get(worksheet, 'Pictures').Insert([pwd '/' filename], 0);
                %picture.Height = worksheetRange.Height;
                %picture.Left = worksheetRange.Left;
                %picture.Top = worksheetRange.Top;
                Log.EndBlock(startAddPngFigure, 4, strcat("Finished inserting png figure for CellID: ", num2str(currentCell.ID), " Pulse Detection"));

                % if neccessary - save figure to file
                if (Parameters.Visualization.SaveVisualizedCellsToFiles)
                    fileNameFigurePulseDetection = self.GetFileNameFigurePulsesDetection(currentCell, '.fig');
                    self.SaveCellFigureToFile(figurePulseDetection, currentCell.ID, fileNameFigurePulseDetection);
                end
                % close the figure if it wasn't set for cell 
                if (~currentCell.IsFigurePulseDetectionSet)
                    close(figurePulseDetection);
                end

                % Pulse Analysis figure
                % obtain the figure
                figurePulseAnalysis = currentCell.GetFigurePulseAnalysis();

                % save figure as png
                startSavePngFigure = Log.StartBlock(4, strcat("Started saving png figure for CellID: ", num2str(currentCell.ID), " Pulse Analysis"));
                filename = self.GetFileNameFigurePulsesAnalysis(currentCell, '.png');
                hLegend = findobj(figurePulseAnalysis, 'Type', 'Legend');
                set(hLegend, 'Visible', 'off');
                exportgraphics(figurePulseAnalysis, filename, 'Resolution', 100);
                set(hLegend, 'Visible', 'on');
                Log.EndBlock(startSavePngFigure, 4, strcat("Finished saving png figure for CellID: ", num2str(currentCell.ID), " Pulse Analysis"));

                %FigureUtils.CopyFigureToClipboard(figurePulseAnalysis);

                % insert figure to worksheet
                figure2RangeColumn = 'H';
                worksheetRange = get(worksheet, 'Range', strcat(figure2RangeColumn, num2str(rangeStartIndex)),...
                                                         strcat(figure2RangeColumn, num2str(rangeEndIndex-1)));
                
                startAddPngFigure = Log.StartBlock(4, strcat("Started inserting png figure for CellID: ", num2str(currentCell.ID), " Pulse Analysis"));
                % method 1: use AddPicture to insert png into xlsx file (works with parallelisation)
                Shapes = worksheet.Shapes;
                Shapes.AddPicture(strrep(filename, '/', '\'), 0, 1, worksheetRange.Left, worksheetRange.Top, -1, -1);
                Shapes.Item(Shapes.Count).LockAspectRatio = 'msoTrue';
                Shapes.Item(Shapes.Count).Height = worksheetRange.Height;

                % method 2: use clipboard to paste image into xlsx file (doesn't work with parallelisation)
                %worksheetRange.PasteSpecial();
                %self.e.Selection.ShapeRange.Item(1).Height = worksheetRange.Height;
                % method 3: use Insert to insert png into xlsx file (works with parallelisation but having issues with saving and reading file)
                %picture = get(worksheet, 'Pictures').Insert([pwd '\' filename], 0);
                %picture.Height = worksheetRange.Height;
                %picture.Left = worksheetRange.Left;
                %picture.Top = worksheetRange.Top;
                Log.EndBlock(startAddPngFigure, 4, strcat("Finished inserting png figure for CellID: ", num2str(currentCell.ID), " Pulse Analysis"));

                % if neccessary - save figure to file
                if (Parameters.Visualization.SaveVisualizedCellsToFiles)
                    fileNameFigurePulseAnalysis = self.GetFileNameFigurePulsesAnalysis(currentCell, '.fig');
                    self.SaveCellFigureToFile(figurePulseAnalysis, currentCell.ID, fileNameFigurePulseAnalysis);
                end
                % close the figure if it wasn't set for cell
                if (~currentCell.IsFigurePulseAnalysisSet)
                    close(figurePulseAnalysis);
                end
                
                
                Log.EndBlock(startWriteFigureToReportFile, 3, strcat("Finished writing figures for CellID: ", num2str(currentCell.ID), " to report file"));
            end
        end
        
        function RenameWorkheetsInQCReport(self)

            startRenameSheets = Log.StartBlock(3, strcat("Started renaming Worksheets in file '", self.fileName_QCReport, "'"));
            
            worksheetIndexes = [FileWriter.WorksheetNumber_CellsPassedQC FileWriter.WorksheetNumber_CellsPassedQCStatsAll FileWriter.WorksheetNumber_CellsPassedQCStatsPaced FileWriter.WorksheetNumber_CellsPassedQCData FileWriter.WorksheetNumber_CellsFailedQC];
            worksheetNames = [FileWriter.WorksheetName_CellsPassedQC FileWriter.WorksheetName_CellsPassedQCStatsAll FileWriter.WorksheetName_CellsPassedQCStatsPaced FileWriter.WorksheetName_CellsPassedQCData FileWriter.WorksheetName_CellsFailedQC];

            ExcelUtils.RenameWorkheetsInExcelFile(self.ewb, worksheetIndexes, worksheetNames);
            
            Log.EndBlock(startRenameSheets, 3, strcat("Finished renaming Worksheets in file '", self.fileName_QCReport, "'"));
        end
        

        
        function SaveCellsFiguresToFiles(self)
            % saveas(fig, 'Cell.fig');
            % savefig(fig, 'Cell.fig', 'compact' )
            
            if ((Parameters.QC.IsQCRequired && Parameters.QC.WriteFiguresToQCReportFile)) % i.e. figures already saved to files            
                return;
            end

            cellsNumber = length(self.well.Cells);
            startWriteCellsFiguresToFiles = Log.StartBlock(1, strcat("Started saving ", num2str(cellsNumber), " cells figures for '", self.well.FileName, self.well.FileExt, "' to files"));
            
            for i = 1 : cellsNumber
                cell = self.well.Cells(i);
                
                % save figure for Pulses Detection to file
                figurePulseDetection = cell.GetFigurePulseDetection();
                fileNameFigurePulseDetection = self.GetFileNameFigurePulsesDetection(cell, '.fig');
                self.SaveCellFigureToFile(figurePulseDetection, cell.ID, fileNameFigurePulseDetection);
                if (~cell.IsFigurePulseDetectionSet)
                    close(figurePulseDetection);
                end
                
                % save figure for Pulses Analysis to file
                figurePulseAnalysis = cell.GetFigurePulseAnalysis();
                fileNamePulseAnalysis = self.GetFileNameFigurePulsesAnalysis(cell, '.fig');
                self.SaveCellFigureToFile(figurePulseAnalysis, cell.ID, fileNamePulseAnalysis);
                if (~cell.IsFigurePulseAnalysisSet)
                    close(figurePulseAnalysis);
                end
                
            end
            
            Log.EndBlock(startWriteCellsFiguresToFiles, 1, strcat("Finished saving ", num2str(cellsNumber), " cells figures for file '", self.well.FileName, self.well.FileExt, "'"));

        end
        
        function SaveCellFigureToFile(~, figure, cellID, fileName)
            
            startWriteCellFigureToFile = Log.StartBlock(4, strcat("Started saving CellID_", num2str(cellID), " figure to file '", fileName, "'"));

            FigureUtils.SaveFigureToFile(figure, fileName);
            
            Log.EndBlock(startWriteCellFigureToFile, 4, strcat("Finished saving CellID_", num2str(cellID), " figure to file '", fileName, "'"));
        end
        
        
        
        function OpenExcel(self)
            [self.e, self.ewb] = ExcelUtils.OpenExcelActiveXAndWorkbook(self.fileName_QCReport);
         end
        
        function CloseExcel(self)
             ExcelUtils.CloseExcelActiveXAndWorkbook(self.e, self.ewb);
         end
        
        
        function fileName_FigurePulseDetection = GetFileNameFigurePulsesDetection(self, cell, suffix)
            fileName_FigurePulseDetection = FileWriter.CorrectFileName(fullfile(self.folderName_Figures, strcat(FileWriter.FileName_FigurePulseDetection_Prefix, self.well.FileName, FileWriter.FileName_CellID_Suffix, num2str(cell.ID), FileWriter.FileName_FigurePulseDetection_Suffix, suffix)));
        end

        function fileName_FigurePulseAnalysis = GetFileNameFigurePulsesAnalysis(self, cell, suffix)
             fileName_FigurePulseAnalysis = FileWriter.CorrectFileName(fullfile(self.folderName_Figures, strcat(FileWriter.FileName_FigurePulseAnalysis_Prefix, self.well.FileName, FileWriter.FileName_CellID_Suffix, num2str(cell.ID), FileWriter.FileName_FigurePulseAnalysis_Suffix, suffix)));
        end        
        
        
    end
    
    
    methods (Static)
        
        function correctedFileName = CorrectFileName(fileName)
            correctedFileName = strrep(fileName, '\', '/');
            %correctedFileName = strrep(fileName, '\', '\\');
        end
        
    end
end


