% CLASS DESCRIPTION 
%
% NOTES:
%
% RELEASE VERSION: 0.6
%
% AUTHOR: Anton Shpak (a.shpak@victorchang.edu.au)
%
% DATE: February 2020
classdef PulseDetectionParameters < handle
    
    properties (SetAccess = private, GetAccess = public)
        % specify pulse detection params
        ThresholdPercentage = 5;             % <--- PARAMETER
        % part of signal at start to ignore
        NumberOfSecondsAtStartToIgnore = 1;  % <--- PARAMETER
        NumberOfSamplesAtStartToIgnore = 1;

        %SignalType = SignalType.Calcium; 
        SignalType = SignalType.Voltage; 


        % specify params for false pulses removal
        RemoveFalsePulses_PeakThresholdPercentage = 25;       
        RemoveFalsePulses_DurationThresholdPercentage = 50;  

        % specify params for wavelet for Upstroke Detection
        Denoise_WaveletName = "bior"; % use biorthogonal wavelet
        Denoise_WaveletNumber = 6.8;
        Denoise_WaveletThresholdRule = "Hard";
    end
    
    methods
        % constructor
        function obj = PulseDetectionParameters(thresholdPercentage, numberOfSecondsAtStartToIgnore, signalType,...
                                removeFalsePulses_PeakThresholdPercentage, removeFalsePulses_DurationThresholdPercentage,...
                                denoise_waveletName, denoise_waveletNumber, denoise_waveletThresholdRule)
            if (nargin == 0)
                obj.ThresholdPercentage = 5;
                obj.NumberOfSecondsAtStartToIgnore = 1;
                obj.NumberOfSamplesAtStartToIgnore = 1;

                obj.SignalType = SignalType.Voltage; % SignalType.Calcium; 

                obj.RemoveFalsePulses_PeakThresholdPercentage = 25;       
                obj.RemoveFalsePulses_DurationThresholdPercentage = 50;  

                obj.Denoise_WaveletName = "bior";
                obj.Denoise_WaveletNumber = 6.8;
                obj.Denoise_WaveletThresholdRule = "Hard";
            elseif (nargin == 8)
                obj.ThresholdPercentage = thresholdPercentage;
                obj.NumberOfSecondsAtStartToIgnore = numberOfSecondsAtStartToIgnore;
                obj.NumberOfSamplesAtStartToIgnore = ceil((numberOfSecondsAtStartToIgnore*1000)/Sampling.Period_ms);

                obj.SignalType = signalType; 

                obj.RemoveFalsePulses_PeakThresholdPercentage = removeFalsePulses_PeakThresholdPercentage;       
                obj.RemoveFalsePulses_DurationThresholdPercentage = removeFalsePulses_DurationThresholdPercentage;  

                obj.Denoise_WaveletName = denoise_waveletName;
                obj.Denoise_WaveletNumber = denoise_waveletNumber;
                obj.Denoise_WaveletThresholdRule = denoise_waveletThresholdRule;
            else
                error('Wrong number of input arguments');
            end
        end
    end
end

