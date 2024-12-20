% CLASS DESCRIPTION 
%
% NOTES:
%
% RELEASE VERSION: 0.6
%
% AUTHOR: Anton Shpak (a.shpak@victorchang.edu.au)
%
% DATE: February 2020
classdef Cell < BaseSignal

    
    properties
        % TODO:
        % 1. Remove redundant properties
        % 2. Define proper access level: protected, private etc.
        
        Well;
        Pulses = Pulse.empty;
        
        RawBaselineDelta;
        
        % Wavelets denoising
        Denoised;
        DenoisedBaselineDelta;
        DenoisedBaselineCorrected;
        DenoisedBaselineCorrected_dFdt;
        
        PulseDetectionThresholdValue;
        
        % Analytical
        SNR; % SNR for not-baseline-corrected sugnal
        SNR2; % SNR for baseline-corrected sugnal
        
        HasSpontaneousPulses;
        QCStatus = QCStatus.QC_NotPerformed;
    end
    
    properties (Access = private)
        figurePulseDetection = matlab.ui.Figure.empty;
        figurePulseAnalysis = matlab.ui.Figure.empty;
    end
    
    properties (Dependent)
        RawBaselineCorrected;
        QCStatusString;

        IsFigurePulseDetectionSet;
        IsFigurePulseAnalysisSet;
        
        TitleFigurePulseDetection = "";
        TitleFigurePulseAnalysis = "";
        
        HasPulsesDetected;
    end
    
    methods
        
        % constructor
        function obj = Cell(id, description, comments, times, rawValues)
            % create base class constructor arguments
            if nargin == 0 % NEED THE EMPTY CONSTRUCTOR FOR ARRAY SUPPORT
                argsBase{1} = double.empty;
                argsBase{2} = "";
                argsBase{3} = "";
                argsBase{4} = double.empty;
                argsBase{5} = double.empty;
            elseif nargin == 5
                argsBase{1} = id;
                argsBase{2} = description;
                argsBase{3} = comments;
                argsBase{4} = times;
                argsBase{5} = rawValues;
            else
                error('Wrong number of input arguments')
            end
            
            % call base class constructor
            obj = obj@BaseSignal(argsBase{:}); 
            
            obj.Pulses = Pulse.empty;
        end
        
        function SetFigurePulseDetection(self, fig)
            self.figurePulseDetection = fig;
        end

        function SetFigurePulseAnalysis(self, fig)
            self.figurePulseAnalysis = fig;
        end
        
        function figurePulseDetection = GetFigurePulseDetection(self)
            figurePulseDetection = self.figurePulseDetection;
            if (isequal(figurePulseDetection, matlab.ui.Figure.empty))
                figurePulseDetection = Visualiser.GetFigureForPulseDetection(self, 'off');
            end
        end
        
        function figurePulseAnalysis = GetFigurePulseAnalysis(self)
            figurePulseAnalysis = self.figurePulseAnalysis;
            if (isequal(figurePulseAnalysis, matlab.ui.Figure.empty))
                figurePulseAnalysis = Visualiser.GetFigureForPulseAnalysis(self, 'off');
            end
        end
        
        
        % Dependency properies
        
        function res = get.RawBaselineCorrected(self)
            res = self.Raw - self.RawBaselineDelta; 
        end
        
        function res = get.QCStatusString(self)
            res = QCStatus.ToString(self.QCStatus); %#ok<PROP>
        end
        
        
        function res = get.TitleFigurePulseDetection(self)
            res = strcat('CellID:', " ", num2str(self.ID), ', Pulses Detection  SNR:', " ", num2str(self.SNR2), " [dB]");
        end
        
        function res = get.TitleFigurePulseAnalysis(self)
            res = strcat('CellID:', " ", num2str(self.ID), ', Pulses Analysis  SNR:', " ", num2str(self.SNR2), " [dB]");
        end
        

        function res = get.IsFigurePulseDetectionSet(self)
            res = ~isequal(self.figurePulseDetection, matlab.ui.Figure.empty);
        end
        
        function res = get.IsFigurePulseAnalysisSet(self)
            res = ~isequal(self.figurePulseAnalysis, matlab.ui.Figure.empty);
        end
        
        
        function res = get.HasPulsesDetected(self)
            res = ~isempty(self.Pulses);
        end
    end
end

