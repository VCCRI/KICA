classdef CellAnalyser < handle
% CLASS DESCRIPTION 
%
% NOTES:
%
% RELEASE VERSION: 0.6
%
% AUTHOR: Anton Shpak (a.shpak@victorchang.edu.au)
%
% DATE: February 2020
    
    
    properties (GetAccess = public, SetAccess = protected)
        
        Cell = Cell();
        
    end
    
    properties (Access = private)
        
        % duration
        maxDurationWithinStimWnd = 0;
        minDurationWithinStimWnd = realmax;
        
        meanDurationWithinStimWnd = 0;

        % denoised
        maxPeakDenoisedWithinStimWnd = realmin;
        minPeakDenoisedWithinStimWnd = realmax;

        pulsesDetectionElapsedTime;
        pulsesAnalysisElapsedTime;
       
    end
    
    methods

        % constructor
        function obj = CellAnalyser(cell)
            obj.Cell = cell;

            % duration
            obj.maxDurationWithinStimWnd = 0;
            obj.minDurationWithinStimWnd = realmax;

            % denoised
            obj.maxPeakDenoisedWithinStimWnd = realmin;
            obj.minPeakDenoisedWithinStimWnd = realmax;
            
        end
        
        function StartAnalysis(self)

            startAnalysis = Log.StartBlock(2, strcat("Started analysis of <strong>Cell_ID: ", num2str(self.Cell.ID), "</strong>"));
            
            self.AnalyseCell();
            
            self.AnalysePulses();
        
            self.QualityControl();
            
            self.Visualize();

            Log.EndBlock(startAnalysis, 2, strcat("Finished analysis of Cell_ID: ", num2str(self.Cell.ID)));
            
        end
        
    end
    
    methods (Access = private)
        
        function AnalyseCell(self)
            
            startPulsesDetection = Log.StartBlock(3, strcat("Start Pulses detection for Cell_ID: ", num2str(self.Cell.ID))); 
            
            % denoise the signal, detrend the denoised signal and find
            % first derivative (i.e. velocity change)
            self.CalculateDenoised();
            
            % assign baseline delta to correct the row signal
            self.Cell.RawBaselineDelta = self.Cell.DenoisedBaselineDelta;
            
            % detect pulses based on threshold
            self.DetectPulses();
            
            % calculate SNR
            self.CalculateSNR();
            
            self.pulsesDetectionElapsedTime = Log.EndBlock(startPulsesDetection, 3, strcat("Finished Pulses detection for Cell_ID: ", num2str(self.Cell.ID)), 1);
        end
        
        function AnalysePulses(self)
            
            startPulsesAnalysis = Log.StartBlock(3, strcat("Start Pulses analysis for Cell_ID: ", num2str(self.Cell.ID)));
            
            len = length(self.Cell.Pulses);
            
            if (len > 0)
                for i = 1 : len
                    pulseAnalyser = PulseAnalyser(self.Cell.Pulses(i));
                    pulseAnalyser.StartAnalysis();
                end
            end
            
            self.pulsesAnalysisElapsedTime = Log.EndBlock(startPulsesAnalysis, 3, strcat("Finished Pulses analysis for Cell_ID: ", num2str(self.Cell.ID)), 1);
        end
        
        
        function CalculateDenoised(self)
            self.Cell.Denoised = wdenoise(self.Cell.Raw,...
                                            'Wavelet', strcat(Parameters.PulseDetection.Denoise_WaveletName,...
                                                              num2str(Parameters.PulseDetection.Denoise_WaveletNumber)),...
                                            'DenoisingMethod', 'Bayes',...
                                            'ThresholdRule', Parameters.PulseDetection.Denoise_WaveletThresholdRule); 
            
            % correct the signal at the beginning; 
            if (Parameters.PulseDetection.NumberOfSamplesAtStartToIgnore > 0)
                self.Cell.Denoised(1:Parameters.PulseDetection.NumberOfSamplesAtStartToIgnore) = self.Cell.Denoised(Parameters.PulseDetection.NumberOfSamplesAtStartToIgnore);
            end
                       
            x = (1:length(self.Cell.Denoised))';
            
            [self.Cell.DenoisedBaselineCorrected, self.Cell.DenoisedBaselineDelta] = BaselineCorrector.CorrectBaseline(x, self.Cell.Denoised(x), 'pchip');
            if (Parameters.PulseDetection.NumberOfSamplesAtStartToIgnore > 0)
                self.Cell.DenoisedBaselineCorrected(1:Parameters.PulseDetection.NumberOfSamplesAtStartToIgnore) = 0;
                self.Cell.DenoisedBaselineDelta(1:Parameters.PulseDetection.NumberOfSamplesAtStartToIgnore) = self.Cell.Denoised(1:Parameters.PulseDetection.NumberOfSamplesAtStartToIgnore);
            end
            
            % first derivative
            self.Cell.DenoisedBaselineCorrected_dFdt = diff(self.Cell.DenoisedBaselineCorrected);
            % size correction: add one point at the beginning
            self.Cell.DenoisedBaselineCorrected_dFdt = [self.Cell.DenoisedBaselineCorrected_dFdt(1) self.Cell.DenoisedBaselineCorrected_dFdt']';
        end
        
        
       % detects pulses by intersections with the threshold line
        function DetectPulses(self)
            
            referenceSignal = self.Cell.DenoisedBaselineCorrected;
            
            self.Cell.PulseDetectionThresholdValue = max(referenceSignal)*Parameters.PulseDetection.ThresholdPercentage/100; 
           
            [rises, falls] = Calc.RisesAndFalls(referenceSignal, self.Cell.PulseDetectionThresholdValue);
            
            if (~isempty(falls) && ~isempty(rises))
                if(falls(1) < rises(1))
                    falls(1) = [];
                end
                
                if (isempty(falls))
                    return;
                end
                
                if (falls(end) < rises(end))
                    rises(end) = [];
                end
                
                if (length(falls) == length(rises))

                    rises = floor(rises);
                    falls = ceil(falls);
                                        
                    % if two consequent pulses pulse(i) ends and pulse(i+1) starts in the same point, 
                    % this is same pulse => clean the noise artefact
                    indexesToDeleteFalls = zeros(0, 1);
                    indexesToDeleteRises = zeros(0, 1);
                    ind = 1;
                    for i = 1 : length(rises) - 1
                        if (falls(i) == rises(i+1))
                            indexesToDeleteFalls(ind, 1) = i;
                            indexesToDeleteRises(ind, 1) = i+1;
                            ind = ind + 1;
                        end
                    end
                    falls(indexesToDeleteFalls) = []; % delete unneccesary falls
                    rises(indexesToDeleteRises) = []; % delete unneccesary rises
                    
                    % define array of less memory consuming PulseShort to clean-up and extend pulses
                    pulsesShort(length(rises), 1) = PulseShort(); % allocate memory for array
                    
                    for i = 1 : length(rises)
                        if (rises(i) < falls(i))
                            pulseShort = PulseShort(rises(i), falls(i), self.Cell); 
                            pulsesShort(i) = pulseShort;
                        else
                            % throw exception
                            throw(MException(Error.ID_CellAnalyser_DetectPulsesError, Error.Msg_CellAnalyser_DetectPulsesError_EdgesDontMatch));
                        end
                    end
                    
                    % remove pulses that too short and have too small amlitude
                    self.CalculateMinMaxPeakAndDurationWithinStimWnd(pulsesShort);
                    pulsesShort = self.RemoveFalsePulseDetections(pulsesShort);
                    
                    % shift pulses start to left, end to right to next local minimum
                    self.ExtendPulsesStartAndEndToNextMinimum(pulsesShort);
                    
                    % create full Pulse objects for further analysis
                    self.Cell.Pulses(length(pulsesShort), 1) = Pulse(); % allocate memory for array
                    for i = 1 : length(pulsesShort)
                        self.Cell.Pulses(i) = Pulse(i, "", "", pulsesShort(i).Start, pulsesShort(i).End, self.Cell);
                    end                    
                   
                end
            end
            
        end
     
        
        function ExtendPulsesStartAndEndToNextMinimum(self, pulsesShort)
            
            referenceSignal = self.Cell.DenoisedBaselineCorrected;
            
            for i = 1 : length(pulsesShort)
                % 1 - shift rising edge to left until local minimum
                intervalStart = 1;
                if (i > 1)
                    intervalStart = pulsesShort(i-1).End;
                end
                intervalEnd = pulsesShort(i).Start;
                newStart = pulsesShort(i).Start;
                for k = intervalEnd-1 : -1 : intervalStart
                    if (referenceSignal(k) >= referenceSignal(k+1))
                        newStart = k+1;
                        break;
                    end
                end

                % 2 - shift falling edge to right until local minimum
                intervalStart = pulsesShort(i).End;
                intervalEnd = length(referenceSignal);
                if (i < length(pulsesShort))
                    intervalEnd = pulsesShort(i+1).Start;
                end
                newEnd = pulsesShort(i).End;
                for k = intervalStart+1 : intervalEnd
                    if (referenceSignal(k-1) <= referenceSignal(k))
                        newEnd = k - 1;
                        break;
                    end
                end

                if (newStart ~= pulsesShort(i).Start) || (newEnd ~= pulsesShort(i).End)
                    pulsesShort(i).Update(newStart, newEnd);
                end
            end
            
        end
        
        function CalculateMinMaxPeakAndDurationWithinStimWnd(self, pulsesShort)

            % duration
            self.maxDurationWithinStimWnd = 0;
            self.minDurationWithinStimWnd = realmax;
            
            % denoised 
            self.maxPeakDenoisedWithinStimWnd = realmin;
            self.minPeakDenoisedWithinStimWnd = realmax;

            
            numberOfPulsesWithinStimWnd = 0;
            sumDurationWithinStimWnd = 0;
            
            for i = 1 : length(pulsesShort)
                
                pulseShort = pulsesShort(i);

                isOnFirstStimulus = (pulseShort.Start < Stimulation.StimuliLocations(1) && pulseShort.End > Stimulation.StimuliLocations(1));
                isOnLastStimulus = (pulseShort.Start < Stimulation.StimuliLocations(Stimulation.StimuliNumber) && pulseShort.End > Stimulation.StimuliLocations(Stimulation.StimuliNumber));
                
                % exclude pulses that are on first and last stimuli
                if (pulseShort.IsWithinStimulationWindow && ~isOnFirstStimulus && ~isOnLastStimulus)

                    % duration
                    % calc maxDurationWithinStimWnd
                    if (pulseShort.Duration > self.maxDurationWithinStimWnd)
                        self.maxDurationWithinStimWnd = pulseShort.Duration;
                    end

                    % calc minDurationWithinStimWnd
                    if (self.minDurationWithinStimWnd > pulseShort.Duration)
                        self.minDurationWithinStimWnd = pulseShort.Duration;
                    end

                    numberOfPulsesWithinStimWnd = numberOfPulsesWithinStimWnd + 1;
                    sumDurationWithinStimWnd = sumDurationWithinStimWnd + pulseShort.Duration;

                    
                    % denoised
                    % calc maxPeakDenoisedWithinStimWnd
                    if (pulseShort.MaxDenoised.Value > self.maxPeakDenoisedWithinStimWnd)
                        self.maxPeakDenoisedWithinStimWnd = pulseShort.MaxDenoised.Value;
                    end

                    % calc minPeakDenoisedWithinStimWnd
                    if (self.minPeakDenoisedWithinStimWnd > pulseShort.MaxDenoised.Value)
                        self.minPeakDenoisedWithinStimWnd = pulseShort.MaxDenoised.Value;
                    end
                    
                end
            end
            
            self.meanDurationWithinStimWnd = sumDurationWithinStimWnd / numberOfPulsesWithinStimWnd;

        end        
     
        
        function pulsesShortOut = RemoveFalsePulseDetections(self, pulsesShortIn)
        % clean-up the detected pulses - remove false detections based on duration and amplitude
        
            pulsesShortOut = pulsesShortIn;
            
            % step 1: remove all pulses with peak below the threshold
            peakThreshold = (self.maxPeakDenoisedWithinStimWnd) * Parameters.PulseDetection.RemoveFalsePulses_PeakThresholdPercentage/100;
            
            indexesToDelete = zeros(0, 1);
            ind = 1;
            for i = 1 : length(pulsesShortOut)
                pulseShort = pulsesShortOut(i);
                
                referenceValue = pulseShort.MaxDenoised.Value;
                
                if (referenceValue < peakThreshold)
                    indexesToDelete(ind, 1) = i;
                    ind = ind + 1;
                end
            end
            pulsesShortOut(indexesToDelete) = []; % delete unneccesary pulses
            
            % step 2: recalculate max and min duration and magnitude within stimulation window
            self.CalculateMinMaxPeakAndDurationWithinStimWnd(pulsesShortOut);
            
            % step 3: remove all peaks with duration less than the threshold
            %durationThreshold = (self.minDurationWithinStimWnd)*Parameters.PulseDetection.RemoveFalsePulses_DurationThresholdPercentage/100;
            durationThreshold = (self.meanDurationWithinStimWnd)*Parameters.PulseDetection.RemoveFalsePulses_DurationThresholdPercentage/100;
            
            indexesToDelete = zeros(0, 1);
            ind = 1;
            for i = 1 : length(pulsesShortOut)
                pulseShort = pulsesShortOut(i);
                
                if (pulseShort.Duration < durationThreshold)
                    indexesToDelete(ind, 1) = i;
                    ind = ind + 1;
                end
            end
            pulsesShortOut(indexesToDelete) = []; % delete unneccesary pulses
        end        
        
        
        function CalculateSNR(self)
            
            % Euclidian norm = vector magnitude
            
            % exclude first second of the signal from SNR calculation
            meaningfulSignalStart = 1;
            if (Parameters.PulseDetection.NumberOfSamplesAtStartToIgnore > 0)
                meaningfulSignalStart = Parameters.PulseDetection.NumberOfSamplesAtStartToIgnore;
            end
            
            signalDenoised = self.Cell.Denoised(meaningfulSignalStart : end); % self.Cell.Denoised
            signalRaw = self.Cell.Raw(meaningfulSignalStart : end); % self.Cell.Raw
            
            self.Cell.SNR = -20*log10(norm(abs(signalDenoised - signalRaw))/norm(signalDenoised));
            %self.Model.SNR = snr(denoisedSignal, abs(denoisedSignal- self.Model.Raw));
            
            signalDenoisedBaselineCorrected = self.Cell.DenoisedBaselineCorrected(meaningfulSignalStart : end); % self.Cell.DenoisedBaselineCorrected
            signalRawBaselineCorrected = self.Cell.RawBaselineCorrected(meaningfulSignalStart : end); % self.Cell.RawBaselineCorrected
            self.Cell.SNR2 = snr(signalDenoisedBaselineCorrected, abs(signalRawBaselineCorrected - signalDenoisedBaselineCorrected));
        end
        
        function Visualize(self)

            if (Parameters.Visualization.ShowVisualizedCells)
                
                visualisationStart = Log.StartBlock(3, strcat("Started creating Visualization of Cell_ID: ", num2str(self.Cell.ID)));
                
                visibleOnOff = 'on';
                
                % visualize Pulse Detection
                self.Cell.SetFigurePulseDetection(Visualiser.GetFigureForPulseDetection(self.Cell, visibleOnOff));

                % visualize Pulse Analysis
                self.Cell.SetFigurePulseAnalysis(Visualiser.GetFigureForPulseAnalysis(self.Cell, visibleOnOff));
                
                Log.EndBlock(visualisationStart, 3, strcat("Finished creating Visualization of Cell_ID: ", num2str(self.Cell.ID)), 1);
            end
            
        end
        
        function QualityControl(self)
            if (~Parameters.QC.IsQCRequired)
                Log.Message(3, strcat("QC of Cell_ID:", " ", num2str(self.Cell.ID), " not requested"));
                return;
            end
            
            startQC = Log.StartBlock(3, strcat("Started QC of Cell_ID:", " ", num2str(self.Cell.ID)));
            
            self.Cell.QCStatus = bitor(self.Cell.QCStatus, self.CheckForSNR());
            self.Cell.QCStatus = bitor(self.Cell.QCStatus, self.CheckForNoPulsesDetected());
            self.Cell.QCStatus = bitor(self.Cell.QCStatus, self.CheckForPulsesMissingStimuli());
            self.Cell.QCStatus = bitor(self.Cell.QCStatus, self.CheckForPulsesSpanMoreThanOneStimilus());
            
            % if at least one QC stage failed, exclude QC_OK from the QC result
            if (self.Cell.QCStatus ~= QCStatus.QC_OK) && (bitand(self.Cell.QCStatus, QCStatus.QC_OK) == QCStatus.QC_OK)
                self.Cell.QCStatus = bitxor(self.Cell.QCStatus, QCStatus.QC_OK);
            end

            Log.EndBlock(startQC, 3, strcat("Finished QC of Cell_ID:", " ", num2str(self.Cell.ID), ", QCStatus: <strong>", QCStatus.ToString(self.Cell.QCStatus), "</strong>"), 1);
        end
        
        function res = CheckForSNR(self)
            res = QCStatus.QC_NotPerformed;
            
            if (Parameters.QC.CheckForSNR)
                if (self.Cell.SNR2 >= Parameters.QC.SNR_Threshold)
                    res = QCStatus.QC_OK;
                else
                    res = QCStatus.QC_Failed_CheckForSNR;
                end
            end
        end

        function res = CheckForNoPulsesDetected(self)
            res = QCStatus.QC_NotPerformed;
            
            if (Parameters.QC.CheckForNoPulsesDetected)
                if (self.Cell.HasPulsesDetected)
                    res = QCStatus.QC_OK;
                else
                    res = QCStatus.QC_Failed_CheckForNoPulsesDetected;
                end
            end
        end
        
        function res = CheckForPulsesMissingStimuli(self)
            res = QCStatus.QC_NotPerformed;
            
            if (Parameters.QC.CheckForPulsesMissingStimuli)
                if (self.Cell.SNR2 >= Parameters.QC.SNR_Threshold)
                    res = QCStatus.QC_OK;
                else
                    res = QCStatus.QC_Failed_CheckForPulsesMissingStimuli;
                end
            end
        end

        function res = CheckForPulsesSpanMoreThanOneStimilus(self)
            res = QCStatus.QC_NotPerformed;
            
            if (Parameters.QC.CheckForPulsesSpanMoreThanOneStimilus)
                if (self.Cell.SNR2 >= Parameters.QC.SNR_Threshold)
                    res = QCStatus.QC_OK;
                else
                    res = QCStatus.QC_Failed_CheckForPulsesSpanMoreThanOneStimilus;
                end
            end
        end
        
        
    end % methods
    
    
end % class

