classdef Parameters < handle
% CLASS DESCRIPTION:
% Singleton to keep globl parametrs for all parts of the application
%
% NOTES:
%
% RELEASE VERSION: 0.6
%
% AUTHOR: Anton Shpak (a.shpak@victorchang.edu.au)
%
% DATE: February 2020

    properties (Access = private)
        
        pulseDetectionParameters = PulseDetectionParameters();
        
        pulseAnalysisParameters = PulseAnalysisParameters();
        
        visualizationParameters = VisualizationParameters();
        
        qcParameters = QCParameters();
    end
    
    methods
        
        % constructor
        function obj = Parameters()
        end
        
    end
    
    methods (Static)
        
        function inst = Instance()
            persistent obj; 
            
            if isempty(obj)
                obj = Parameters;
            end
            
            inst = obj;
        end

        
        function Init(pulseDetectionParameters, pulseAnalysisParameters, visualizationParameters, qcParameters)
            
            inst = Parameters.Instance();
            
            % copy values
            inst.pulseDetectionParameters = pulseDetectionParameters;

            inst.pulseAnalysisParameters = pulseAnalysisParameters;

            inst.visualizationParameters = visualizationParameters;
            
            inst.qcParameters = qcParameters;
        end
       
        
        % PulseDetectionParameters
        function res = PulseDetection()
            res = Parameters.Instance().pulseDetectionParameters;
        end
        
        
        % PulseAnalysisParameters
        function res = PulseAnalysis()
            res = Parameters.Instance().pulseAnalysisParameters;
        end

       
        % VisualizationParameters
        function res = Visualization()
            res = Parameters.Instance().visualizationParameters;
        end
        

        % QCParameters
        function res = QC()
            res = Parameters.Instance().qcParameters;
        end
       
    end
end

