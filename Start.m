% DESCRIPTION 
% Script to start the application. Conntains all the parametrs settings.
%
% NOTES:
%
% RELEASE VERSION: 0.6
%
% AUTHORS: Satya Arjunan (s.arjunan@victorchang.edu.au)
%          Anton Shpak (a.shpak@victorchang.edu.au)
%
% DATE: February 2020


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
if (selection == 1 | selection == 2)
  % Select a folder containing all csv data files
  folder = uigetdir(pwd, "Select folder containing csv data files");
  % return if user pressed cancel button
  if (folder == 0)
    return
  end

  % Exit program if no csv files found in the folder 
  csv_files = dir(fullfile(folder, '*.csv'));
  if (length(csv_files) == 0)
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
  clearvars -except fileFullName
  %% start timer
  fileStartTime = Log.StartBlock(1, strcat("Started analysis of one file '", fileFullName, "'"));
  %% read data from file to table

  tableData = FileReader.ReadFileToTable(fileFullName);

  %% initialize Sampling
  % Watch out - Sampling and Stimulation initialization order
  Sampling.Init(mean(diff(table2array(tableData(:, 1)))));

  % 1. SignalType:
  pulseDetection_signalType = SignalType.Calcium; % <--- PARAMETER
  %pulseDetection_signalType = SignalType.Voltage; % <--- PARAMETER
                                
  % 2. Stimulation parameters
  %stimuliPeriod_ms = 1000;            % <--- PARAMETER
  %stimuliNumber = 10;                 % <--- PARAMETER
  %stimulationStart_ms = 5000;         % <--- PARAMETER
  %stimulusPulseDuration_ms = 7.5; 
  
  % voltage example
  %stimuliPeriod_ms = 1000;            % <--- PARAMETER
  %stimuliNumber = 10;                 % <--- PARAMETER
  %stimulationStart_ms = 5000;         % <--- PARAMETER
  %stimulusPulseDuration_ms = 7.5; 

  % calcium example
  stimuliPeriod_ms = 1670;            % <--- PARAMETER
  stimuliNumber = 9;                 % <--- PARAMETER
  stimulationStart_ms = 5000;         % <--- PARAMETER
  stimulusPulseDuration_ms = 7.5; 
  
  %stimuliPeriod_ms = 1000;            % <--- PARAMETER
  %stimuliNumber = 10;                 % <--- PARAMETER
  %stimulationStart_ms = 10000;         % <--- PARAMETER
  %stimulusPulseDuration_ms = 7.50; 

  % 3. PulseDetection Parameters
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

  % 4. PulseAnalysis Parameters
  % specify APDs to be calculated
  pulseAnalysis_apDurations = [30 50 75 90 95];                % <--- PARAMETER
  pulseAnalysis_apdIsEndPointApproximatedSymbol = "*";
  pulseAnalysis_pulseStartOnStimulusDetectionDelta_ms = 30;   % <--- PARAMETER
  pulseAnalysis_pulseStartOnStimulusDetectionSymbol = "^";
  pulseAnalysis_pulseStartPointType = PulseStartPointType.ActivationPoint; % <--- PARAMETER
                                      %PulseStartPointType.UpstrokeStart
                                      %PulseStartPointType.UpstrokeEnd
                                      
  % 5. Visualization Parameters

  visualize_showVisualizedCells = false;      % <--- PARAMETER
  visualize_saveVisualizedCellsToFiles = true;% <--- PARAMETER

  % 6. Quality Control Parameters

  qc_isQC_Required = true;                    % <--- PARAMETER
  qc_SNR_Threshold = 10;                      % <--- PARAMETER
  qc_writeFiguresToQCReportFile = true;       % <--- PARAMETER
  qc_checkForSNR = true;                      % <--- PARAMETER
  qc_checkForNoPulsesDetected = true;         % <--- PARAMETER
  qc_checkForPulsesMissingStimuli = false;    % <--- PARAMETER (TODO)
  qc_checkForPulsesSpanMoreThanOneStimilus = false;% <--- PARAMETER (TODO)


  %% initialize parameters

  Stimulation.Init(stimulationStart_ms, stimuliPeriod_ms, stimulusPulseDuration_ms, stimuliNumber);

  pulseDetectionParameters = PulseDetectionParameters(pulseDetection_thresholdPercentage, pulseDetection_numberOfSecondsAtStartToIgnore, pulseDetection_signalType,...
                                  pulseDetection_removeFalsePulses_PeakThresholdPercentage, pulseDetection_removeFalsePulses_DurationThresholdPercentage,...
                                  pulseDetection_denoise_waveletName, pulseDetection_denoise_waveletNumber, pulseDetection_denoise_waveletThresholdRule);

  pulseAnalysisParameters = PulseAnalysisParameters(pulseAnalysis_apDurations, pulseAnalysis_apdIsEndPointApproximatedSymbol,...
                                                    pulseAnalysis_pulseStartOnStimulusDetectionDelta_ms, pulseAnalysis_pulseStartOnStimulusDetectionSymbol,...
                                                    pulseAnalysis_pulseStartPointType);

  visualizationParameters = VisualizationParameters(visualize_showVisualizedCells, visualize_saveVisualizedCellsToFiles);

  qcParameters = QCParameters(qc_isQC_Required, qc_SNR_Threshold, qc_writeFiguresToQCReportFile, qc_checkForSNR, qc_checkForNoPulsesDetected, qc_checkForPulsesMissingStimuli, qc_checkForPulsesSpanMoreThanOneStimilus);
                                                
  % initialize Global Parameters
  Parameters.Init(pulseDetectionParameters, pulseAnalysisParameters, visualizationParameters, qcParameters);

                    
  %% run analysis
  wellAnalyser = WellAnalyser(tableData);
  wellAnalyser.StartAnalysis();


  %% end timer
  Log.EndBlock(fileStartTime, 1, strcat("Completed analysis of one file: processed ", num2str(length(wellAnalyser.Well.Cells)), " cells from file '", fileFullName, "'"));
end

