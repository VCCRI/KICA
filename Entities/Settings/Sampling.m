% CLASS DESCRIPTION 
%
% NOTES:
%
% RELEASE VERSION: 0.6
%
% AUTHOR: Anton Shpak (a.shpak@victorchang.edu.au)
%
% DATE: February 2020
classdef Sampling < handle
   
    properties (Access = private)
        samplingPeriod_ms;
    end
    
    
    methods (Access = private)
        % private constructor
        function obj = Sampling()
        end
        
        function res = getSamplingFrequency(self)
            res = 1/(self.samplingPeriod_ms/1000);
        end
        
    end
    
    methods (Static)
        % Singleton implementation
        function inst = Instance()
            persistent obj; 
            
            if isempty(obj)
                obj = Sampling;
            end
            
            inst = obj;
        end

        % initializes the singleton with the SamplingPeriod
        function Init(samplingPeriod_ms)
            inst = Sampling.Instance();
            inst.samplingPeriod_ms = samplingPeriod_ms;
        end
        
        % returns Sampling Period in milliseconds
        function res = Period_ms()
            res = Sampling.Instance().samplingPeriod_ms;
        end

        % returns Sampling Frequency (Hz)
        function res = Frequency()
            res = Sampling.Instance().getSamplingFrequency;
        end

    end

end

