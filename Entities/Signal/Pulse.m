% CLASS DESCRIPTION 
%
% NOTES:
%
% RELEASE VERSION: 0.6
%
% AUTHOR: Anton Shpak (a.shpak@victorchang.edu.au)
%
% DATE: February 2020
classdef Pulse < PulseShort
    
    properties(GetAccess = public, SetAccess = private)
        
        % wavelet denoised signal
        Denoised_dFdt = double.empty;
        MaxDenoised_dFdt = PointInPulse();
        MinDenoised_dFdt = PointInPulse();        
        
        SubPulses = SubPulse.empty;
        
        % Analytical
        APDs = APD.empty;        
        APD_30_90_Ratio;

        Rise_10_90 = Interval.empty;
        Fall_90_10 = Interval.empty;
        
        ActivationPoint = PointInPulse.empty;
        PulseStartOnStimulusNumber = -1;
    end
       
    properties(Dependent)
        
        Upstroke;
        UpstrokePeakPoint;
        UpstrokeRiseTime_ms;
        ActivationPointTime_ms;
       
        IsDurationGreaterThanStimuliInterval;
        IsPulseStartOnStimulus;
    end
    
    methods
        
        % Constructor
        function obj = Pulse(id, description, comments, startLocation, endLocation, cell)
            
            % create base class constructor arguments
            if nargin == 0 % NEED THE EMPTY CONSTRUCTOR FOR ARRAY SUPPORT
                argsBase = {};
            elseif nargin == 6
                argsBase{1} = startLocation;
                argsBase{2} = endLocation;
                argsBase{3} = cell; 
                argsBase{4} = id;
                argsBase{5} = description;
                argsBase{6} = comments;

            else
                error('Wrong number of input arguments');
            end

            % Call base class constructor
            obj@PulseShort(argsBase{:});       
         
            if (nargin == 0)
            elseif (nargin == 6)
                % init properties
                obj.Denoised_dFdt = cell.DenoisedBaselineCorrected_dFdt(startLocation : endLocation);
                
                % create APDs
                obj.APDs(length(Parameters.PulseAnalysis.APDs), 1) = APD;
                apdsToDetect = Parameters.PulseAnalysis.APDs;
                for i = 1 : length(apdsToDetect)
                    apd = APD(obj, apdsToDetect(i));
                    obj.APDs(i, 1) = apd;
                end
                
                obj.Rise_10_90 = Interval(obj, 1, "Rise 10 to 90", "");
                obj.Fall_90_10 = Interval(obj, 2, "Fall 90 to 10", "");
                
            else
                error('Wrong number of input arguments')
            end
           
            obj.Init();
        end

        
        %Dependent properties

        % Upstroke
        function res = get.Upstroke(self)
            if (isempty(self.SubPulses))
                res = Upstroke.empty; %#ok<PROP>
            else
                res = self.SubPulses(1).Upstroke;
            end
        end
        
        
        function res = get.UpstrokePeakPoint(self)
            if (isempty(self.Upstroke))
                res = PointInPulse.empty;
            else
                res = self.SubPulses(1).PeakPoint; % max of all UpDowns in the SubPulse
            end
        end
        
        function res = get.UpstrokeRiseTime_ms(self)
            if (isempty(self.Upstroke))
                res = double.empty;
            else
                res = self.Upstroke.RiseTime_ms;
            end
        end        
        % Activation Point
        % activation point time
        function res = get.ActivationPointTime_ms(self)
            % perform correction by -1 as indexes in array start with 1
            res = (self.ActivationPoint.LocationInCell - 1) * Sampling.Period_ms;
        end

        
        % Analytical properties
        function res = get.IsDurationGreaterThanStimuliInterval(self)
            res = self.Duration_ms > Stimulation.StimuliPeriod_ms;
        end
        
        function res = get.IsPulseStartOnStimulus(self)
            res = self.PulseStartOnStimulusNumber > 0;
        end
        
        
        % setters
        % ActivationPoint
        function SetValues_ActivationPoint(self, activationPointLocation, activationPointValue)
            self.ActivationPoint = PointInPulse(activationPointLocation, self.ToLocationInCell(activationPointLocation), activationPointValue);
        end

        % Pulse Start On Stimulus
        function SetValue_PulseStartOnStimulusNumber(self, pulseStartOnStimulusNumber)
            self.PulseStartOnStimulusNumber = pulseStartOnStimulusNumber;
        end
        
        function SetValue_APD_30_90_Ratio(self, APD_30_90)
            self.APD_30_90_Ratio = APD_30_90;
        end

        function SetValues_SubPulses(self, subPulses)
            self.SubPulses = subPulses;
        end
        
    end
    
    methods (Access = protected)
        
        % performs initial calculations
        function Init(self)
            Init@PulseShort(self);
            
            [maxDenoised_dFdtValue, maxDenoised_dFdtLocation] = max(self.Denoised_dFdt);
            self.MaxDenoised_dFdt = PointInPulse(maxDenoised_dFdtLocation, self.ToLocationInCell(maxDenoised_dFdtLocation), maxDenoised_dFdtValue);
            
            [minDenoised_dFdtValue, minDenoised_dFdtLocation] = min(self.Denoised_dFdt);
            self.MinDenoised_dFdt = PointInPulse(minDenoised_dFdtLocation, self.ToLocationInCell(minDenoised_dFdtLocation), minDenoised_dFdtValue);
        end
        
        
    end
        
end

