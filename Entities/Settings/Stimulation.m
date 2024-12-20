% CLASS DESCRIPTION 
%
% NOTES:
%
% RELEASE VERSION: 0.6
%
% AUTHOR: Anton Shpak (a.shpak@victorchang.edu.au)
%
% DATE: February 2020
classdef Stimulation < handle
    
    properties (Access = private)
        % [ms]
        stimulationStart_ms = double.empty;
        stimulationEnd_ms = double.empty;
        
        stimuliPeriod_ms = double.empty;
        stimulusPulseDuration_ms = double.empty;

        
        %[samples]
        stimulationStart = double.empty;
        stimulationEnd = double.empty;
        
        stimuliPeriod = double.empty;
        stimulusPulseDuration = double.empty;

        
        stimulationFrequency = double.empty; % [Hz]
        
        stimuliNumber = double.empty;

        stimuliLocations;
    end
    
    
    methods (Access = private)

        % private constructor
        function obj = Stimulation()
        end
        
        % calculates all the parametrs based on the initial values
        function self = CalcParams(self)
            % calculate end of the stimulation period, i.e. start of the last stimulus
            self.stimulationEnd_ms = self.stimulationStart_ms + (self.stimuliNumber - 1) * self.stimuliPeriod_ms;
            
            % convert from [ms] to [samples]
            self.stimulusPulseDuration = self.stimulusPulseDuration_ms / Sampling.Period_ms;

            self.stimulationStart = self.stimulationStart_ms / Sampling.Period_ms; %- stimulusPulseDurationIndexUnits
            self.stimulationEnd = self.stimulationEnd_ms / Sampling.Period_ms;
            
            self.stimuliPeriod = self.stimuliPeriod_ms / Sampling.Period_ms;
            
            self.stimulationFrequency = 1/(self.stimuliPeriod_ms/1000);
            
            % calculate stimuli locations
            for i = 0 : self.stimuliNumber-1
                self.stimuliLocations(i+1) = ((self.stimulationStart_ms + (self.stimuliPeriod_ms * i))/Sampling.Period_ms)+1;
            end
        end
        
    end
    
    methods (Static)
        % Singleton implementation
        function inst = Instance()
            persistent obj; 
            
            if isempty(obj)
                obj = Stimulation;
            end
            
            inst = obj;
        end

        % initializes the singleton 
        function Init(stimulationStart_ms, stimuliPeriod_ms, stimulusPulseDuration_ms, stimuliNumber)
            inst = Stimulation.Instance();
            
            % copy values
            inst.stimulationStart_ms = stimulationStart_ms;
            inst.stimuliPeriod_ms = stimuliPeriod_ms;
            inst.stimulusPulseDuration_ms = stimulusPulseDuration_ms;
            inst.stimuliNumber = stimuliNumber;
            
            % initialize array
            inst.stimuliLocations = zeros(inst.StimuliNumber, 1);

            % calculate all the parametrs based on the initial values
            inst.CalcParams();

        end
        
        % [ms]
        function res = StimulationStart_ms()
            res = Stimulation.Instance().stimulationStart_ms;
        end
        
        function res = StimulationEnd_ms()
            res = Stimulation.Instance().stimulationEnd_ms;
        end
        
        function res = StimuliPeriod_ms()
            res = Stimulation.Instance().stimuliPeriod_ms;
        end
        
        function res = StimulusPulseDuration_ms()
            res = Stimulation.Instance().stimulusPulseDuration_ms;
        end
        
        % [samples]
        function res = StimulationStart()
            res = Stimulation.Instance().stimulationStart;
        end
            
        function res = StimulationEnd()
            res = Stimulation.Instance().stimulationEnd;
        end
        
        function res = StimuliPeriod()
            res = Stimulation.Instance().stimuliPeriod;
        end
        
        function res = StimulusPulseDuration()
            res = Stimulation.Instance().stimulusPulseDuration;
        end
        
        
        % stimuli
        function res = StimuliLocations(i)
            if nargin == 0
                res = Stimulation.Instance().stimuliLocations;
            elseif nargin == 1
                res = Stimulation.Instance().stimuliLocations(i);
            else
                error('Wrong number of input arguments');
            end
        end
        
        function res = StimuliNumber()
            res = Stimulation.Instance().stimuliNumber;
        end

        function res = StimulationFrequency()
            res = Stimulation.Instance().stimulationFrequency;
        end
        
    end
end

