% CLASS DESCRIPTION 
%
% NOTES:
%
% RELEASE VERSION: 0.6
%
% AUTHOR: Anton Shpak (a.shpak@victorchang.edu.au)
%
% DATE: February 2020
classdef PulseAnalysisParameters < handle
    
    properties (SetAccess = private, GetAccess = public)
        % APDs to detect
        APDs = zeros(0, 1);
        % symbol to be added after the APD value in the QC report if the APD's end point was not properly detected
        APDIsEndPointApproximatedSymbol = "*";
        
       PulseStartOnStimulusDetectionDelta_ms = 10;
       % symbol to be added after the PulseStart in the QC report if the Pulse Peak is On Stimulus
       PulseStartOnStimulusDetectionSymbol = "^";
       
       PulseStartPointType = PulseStartPointType.ActivationPoint;
    end
    
    methods

        % constructor
        function obj = PulseAnalysisParameters(apDurations, apdIsEndPointApproximatedSymbol, pulseStartOnStimulusDetectionDelta_ms, pulseStartOnStimulusDetectionSymbol, pulseStartPointType)
            if (nargin == 0)
                obj.APDs = zeros(0, 1);
                obj.APDIsEndPointApproximatedSymbol = "*";
                obj.PulseStartOnStimulusDetectionDelta_ms = 10;
                obj.PulseStartOnStimulusDetectionSymbol = "^";
                obj.PulseStartPointType = PulseStartPointType.ActivationPoint;
            elseif (nargin == 5)
                obj.APDs = apDurations;
                obj.APDIsEndPointApproximatedSymbol = apdIsEndPointApproximatedSymbol;
                obj.PulseStartOnStimulusDetectionDelta_ms = pulseStartOnStimulusDetectionDelta_ms;
                obj.PulseStartOnStimulusDetectionSymbol = pulseStartOnStimulusDetectionSymbol;
                obj.PulseStartPointType = pulseStartPointType;
            else
                error('Wrong number of input arguments');
            end
        end
        
    end
end

