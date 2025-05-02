% DESCRIPTION
% Script to start the application. Conntains all the parametrs settings.
%
% NOTES:
%
% RELEASE VERSION: 0.7 (Added time window filtering)
%
% AUTHORS: Satya Arjunan (s.arjunan@victorchang.edu.au)
%          Anton Shpak (a.shpak@victorchang.edu.au)
%          AI Adaptation
%
% DATE: March 2024


%% include subfolders
addpath Lib
addpath Utils
addpath IO
addpath Analysers
addpath Entities
addpath Entities/Base
addpath Entities/Settings
addpath Entities/Signal
addpath Entities/Enums

%% load data

options = {'Parallel analyse csv files', 'Sequential analyse csv files',...
  'Analyse a csv file'};
selection = listdlg('PromptString', 'What would you like to do?',...
  'SelectionMode', 'single', 'ListString', options);
doubleFileSep = strcat(filesep, filesep);

% If analyse multiple files
if (selection == 1 || selection == 2) % Use || for logical OR
  % Select a folder containing all csv data files
  folder = uigetdir(pwd, "Select folder containing csv data files");
  % return if user pressed cancel button
  if (folder == 0)
    return
  end

  % Exit program if no csv files found in the folder
  csv_files = dir(fullfile(folder, '*.csv'));
  if (isempty(csv_files)) % Use isempty for checking empty arrays
    Log.ErrorMessage(0,...
      strcat("Error: No csv files found in the selected folder, ",...
        folder, ", exiting."));
    return
  end

  % Analyse each csv file in the folder
  % In parallel
  if (selection == 1)
    totalStartTime = Log.StartBlock(0,...
      strcat("Started parallel KIC data analysis of ",...
        num2str(length(csv_files)), " file(s)"));
    parfor i = 1:length(csv_files)
      fileFullName = strrep(strrep(string(fullfile(folder,...
        csv_files(i).name)), doubleFileSep, filesep), filesep, doubleFileSep);
      analyse_csv_file(fileFullName);
    end
    Log.EndBlock(totalStartTime, 0,...
      strcat("Finished parallel KIC data analysis of ",...
        num2str(length(csv_files)), " file(s)"));
  % Sequentially
  else
    totalStartTime = Log.StartBlock(0,...
      strcat("Started sequential KIC data analysis of ",...
        num2str(length(csv_files)), " file(s)"));
    for i = 1 : length(csv_files)
      fileFullName = strrep(strrep(string(fullfile(folder,...
        csv_files(i).name)), doubleFileSep, filesep), filesep, doubleFileSep);
      analyse_csv_file(fileFullName);
    end
    Log.EndBlock(totalStartTime, 0,...
      strcat("Finished sequential KIC data analysis of ",...
        num2str(length(csv_files)), " file(s)"));
  end

% If analyse a single file
elseif (selection == 3)
  [file, folder] = uigetfile('*.csv');
  % return if user pressed cancel button
  if (file == 0)
      return
  end
  fileFullName = strrep(strrep(string(fullfile(folder, file)), doubleFileSep, filesep),...
    filesep, doubleFileSep);
  [~, ~, fileExt] = fileparts(fileFullName);
  if (~isequal(fileExt, ".csv"))
    Log.ErrorMessage(0, "Error: Please, select a *.csv file");
    return
  end
  analyse_csv_file(fileFullName);

% Return if cancelled file or folder selection
else
  return
end

function analyse_csv_file(fileFullName)
  clearvars -except fileFullName % Keep this line
  %% start timer
  fileStartTime = Log.StartBlock(1, strcat("Started analysis of one file '", fileFullName, "'"));

  % --- USER PARAMETERS START ---

  % 1. Define Time Window for Analysis
  analysisStart_ms = 500; % [ms] <--- PARAMETER (Set to desired start time, e.g., 5000. Default: -inf for start of data)
  analysisEnd_ms = inf;   % [ms] <--- PARAMETER (Set to desired end time, e.g., 15000. Default: +inf for end of data)

  % 2. SignalType:
  %pulseDetection_signalType = SignalType.Calcium; % <--- PARAMETER
  pulseDetection_signalType = SignalType.Voltage; % <--- PARAMETER

  % 3. Stimulation parameters
  % voltage example
  stimuliPeriod_ms = 1000;            % <--- PARAMETER
  stimuliNumber = 10;                 % <--- PARAMETER
  stimulationStart_ms = 5000;         % <--- PARAMETER
  stimulusPulseDuration_ms = 7.5;

  %% calcium example
  %stimuliPeriod_ms = 1670;            % <--- PARAMETER
  %stimuliNumber = 9;                 % <--- PARAMETER
  %stimulationStart_ms = 5000;         % <--- PARAMETER
  %stimulusPulseDuration_ms = 7.5;

  % 4. PulseDetection Parameters
  % threshold to detect pulses
  pulseDetection_thresholdPercentage = 20;             % <--- PARAMETER
  % part of signal at start to ignore
  pulseDetection_numberOfSecondsAtStartToIgnore = 0;  % <--- PARAMETER

  % specify params for false pulses removal
  pulseDetection_removeFalsePulses_PeakThresholdPercentage = 25;
  pulseDetection_removeFalsePulses_DurationThresholdPercentage = 25;

  % specify params for wavelet for Upstroke Detection
  pulseDetection_denoise_waveletName = "bior"; % use biorthogonal wavelet
  pulseDetection_denoise_waveletNumber = 6.8;
  pulseDetection_denoise_waveletThresholdRule = "Hard";

  % 5. PulseAnalysis Parameters
  % specify APDs to be calculated
  pulseAnalysis_apDurations = [30 50 75 90 95];                % <--- PARAMETER
  pulseAnalysis_apdIsEndPointApproximatedSymbol = "*";
  pulseAnalysis_pulseStartOnStimulusDetectionDelta_ms = 30;   % <--- PARAMETER
  pulseAnalysis_pulseStartOnStimulusDetectionSymbol = "^";
  pulseAnalysis_pulseStartPointType = PulseStartPointType.ActivationPoint; % <--- PARAMETER
                                      %PulseStartPointType.UpstrokeStart
                                      %PulseStartPointType.UpstrokeEnd

  % 6. Visualization Parameters
  visualize_showVisualizedCells = false;      % <--- PARAMETER
  visualize_saveVisualizedCellsToFiles = true;% <--- PARAMETER

  % 7. Quality Control Parameters
  qc_isQC_Required = true;                    % <--- PARAMETER
  qc_SNR_Threshold = 10;                      % <--- PARAMETER
  qc_writeFiguresToQCReportFile = true;       % <--- PARAMETER
  qc_checkForSNR = true;                      % <--- PARAMETER
  qc_checkForNoPulsesDetected = true;         % <--- PARAMETER
  qc_checkForPulsesMissingStimuli = false;    % <--- PARAMETER (TODO)
  qc_checkForPulsesSpanMoreThanOneStimulus = false;% <--- PARAMETER (TODO)

  % --- USER PARAMETERS END ---


  %% read data from file to table
  % Pass the start and end time parameters to the reader
  tableData = FileReader.ReadFileToTable(fileFullName, analysisStart_ms, analysisEnd_ms);

  % Add a check here: If filtering resulted in no data or too little data, abort.
  if isempty(tableData) || height(tableData) < 2 % Need at least 2 points for diff/analysis
     Log.ErrorMessage(1, strcat("Analysis aborted for file '", fileFullName, "' as no data remains after time window filtering or the resulting data is too short."));
     Log.EndBlock(fileStartTime, 1, strcat("Aborted analysis of one file: '", fileFullName, "' (No data in time window or too short)"));
     return; % Stop processing this file
  end


  %% initialize Sampling
  % Watch out - Sampling and Stimulation initialization order
  timeCol = table2array(tableData(:, 1));
  if length(timeCol) > 1
      samplingPeriod = mean(diff(timeCol));
  else
      % Handle case with only one data point after filtering, maybe default or error
      Log.ErrorMessage(1, "Only one data point remains after time filtering, cannot determine sampling period. Aborting analysis.");
      Log.EndBlock(fileStartTime, 1, strcat("Aborted analysis of one file: '", fileFullName, "' (Only one data point)"));
      return; % Stop processing this file
  end
  Sampling.Init(samplingPeriod); % Use calculated sampling period


  %% initialize parameters

  Stimulation.Init(stimulationStart_ms, stimuliPeriod_ms, stimulusPulseDuration_ms, stimuliNumber);

  pulseDetectionParameters = PulseDetectionParameters(analysisStart_ms, analysisEnd_ms, pulseDetection_thresholdPercentage, pulseDetection_numberOfSecondsAtStartToIgnore, pulseDetection_signalType,...
                                  pulseDetection_removeFalsePulses_PeakThresholdPercentage, pulseDetection_removeFalsePulses_DurationThresholdPercentage,...
                                  pulseDetection_denoise_waveletName, pulseDetection_denoise_waveletNumber, pulseDetection_denoise_waveletThresholdRule);

  pulseAnalysisParameters = PulseAnalysisParameters(pulseAnalysis_apDurations, pulseAnalysis_apdIsEndPointApproximatedSymbol,...
                                                    pulseAnalysis_pulseStartOnStimulusDetectionDelta_ms, pulseAnalysis_pulseStartOnStimulusDetectionSymbol,...
                                                    pulseAnalysis_pulseStartPointType);

  visualizationParameters = VisualizationParameters(visualize_showVisualizedCells, visualize_saveVisualizedCellsToFiles);

  qcParameters = QCParameters(qc_isQC_Required, qc_SNR_Threshold, qc_writeFiguresToQCReportFile, qc_checkForSNR, qc_checkForNoPulsesDetected, qc_checkForPulsesMissingStimuli, qc_checkForPulsesSpanMoreThanOneStimulus);

  % initialize Global Parameters
  Parameters.Init(pulseDetectionParameters, pulseAnalysisParameters, visualizationParameters, qcParameters);


  %% run analysis
  wellAnalyser = WellAnalyser(tableData);

  wellAnalyser.StartAnalysis();


  %% end timer
  Log.EndBlock(fileStartTime, 1, strcat("Completed analysis of one file: processed ", num2str(length(wellAnalyser.Well.Cells)), " cells from file '", fileFullName, "'"));
end
% --- END OF FILE Start.m ---
