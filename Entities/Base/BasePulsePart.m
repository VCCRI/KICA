classdef (Abstract) BasePulsePart < matlab.mixin.Copyable % handle
% CLASS DESCRIPTION 
%
% NOTES:
%
% RELEASE VERSION: 0.6
%
% AUTHOR: Anton Shpak (a.shpak@victorchang.edu.au)
%
% DATE: February 2020
    properties(GetAccess = public, SetAccess = protected)
        Pulse = Pulse();
    end

    properties (Dependent)
        StartPoint;
        EndPoint;
        PeakPoint;
    end

    
    methods
        % constructor
        function obj = BasePulsePart(pulse)
            
            if (nargin == 0) 
                obj.Pulse = Pulse();
            elseif (nargin == 1)
                obj.Pulse = pulse;
            else
                error('Wrong number of input arguments');
            end
        end
        
        
        % Dependent Properties
        function res = get.StartPoint(self)
            res = self.getStartPoint();
        end
        
        function res = get.EndPoint(self)
            res = self.getEndPoint();
        end

        function res = get.PeakPoint(self)
            res = self.getPeakPoint();
        end
        
    end    
    
    methods (Abstract, Access = protected)
        getStartPoint(self);
        getEndPoint(self);
        getPeakPoint(self);
    end
    
    
end

