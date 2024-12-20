% CLASS DESCRIPTION 
%
% NOTES:
%
% RELEASE VERSION: 0.6
%
% AUTHOR: Anton Shpak (a.shpak@victorchang.edu.au)
%
% DATE: February 2020
classdef QCParameters < handle
    
    properties (SetAccess = private, GetAccess = public)

        IsQCRequired = false;
        WriteFiguresToQCReportFile = false;
        SNR_Threshold = 5;
        CheckForSNR = false;
        CheckForPulsesMissingStimuli = false;
        CheckForPulsesSpanMoreThanOneStimilus = false;
        CheckForNoPulsesDetected = false;
        
    end
    
    methods
        
        function obj = QCParameters(isQC_Required, SNR_Threshold, writeFiguresToQCReportFile,... 
                                checkForSNR, qc_checkForNoPulsesDetected,... 
                                checkForPulsesMissingStimuli,... 
                                checkForPulsesSpanMoreThanOneStimilus)
                              
            if (nargin == 0)
                obj.IsQCRequired = false;
                obj.SNR_Threshold = 5;
                obj.WriteFiguresToQCReportFile = false;
                obj.CheckForSNR = false;
                obj.CheckForPulsesMissingStimuli = false;
                obj.CheckForPulsesSpanMoreThanOneStimilus = false;
                obj.CheckForNoPulsesDetected = false;
            elseif (nargin == 7)
                obj.IsQCRequired = isQC_Required;
                obj.SNR_Threshold = SNR_Threshold;
                obj.WriteFiguresToQCReportFile = writeFiguresToQCReportFile;
                obj.CheckForSNR = checkForSNR;
                obj.CheckForPulsesMissingStimuli = checkForPulsesMissingStimuli;
                obj.CheckForPulsesSpanMoreThanOneStimilus = checkForPulsesSpanMoreThanOneStimilus;
                obj.CheckForNoPulsesDetected = qc_checkForNoPulsesDetected;
            else
                error('Wrong number of input arguments')
            end

        end
    end
    
end

