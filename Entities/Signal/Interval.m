% CLASS DESCRIPTION 
%
% NOTES:
%
% RELEASE VERSION: 0.6
%
% AUTHOR: Anton Shpak (a.shpak@victorchang.edu.au)
%
% DATE: February 2020

classdef Interval < BaseEntity
    
    properties (GetAccess = public, SetAccess = protected)
        Pulse;% = Pulse();
        
        StartPoint = PointInPulse();
        EndPoint = PointInPulse();

        IsStartPointApproximated = false;
        IsEndPointApproximated = false;
    end
    
    properties (Dependent)
        Duration;
        Duration_ms;
    end
    

    methods
        % constructor
        function obj = Interval(pulse, id, description, comments)
            
            if (nargin == 0) || (nargin == 1)
                argsBase = {};
            elseif (nargin == 4)
                argsBase{1} = id;   
                argsBase{2} = description;
                argsBase{3} = comments;
            else
                error('Wrong number of input arguments');
            end

            % Call base class constructor
            obj@BaseEntity(argsBase{:});       

            if (nargin == 0)
                %obj.Pulse = Pulse();
            elseif (nargin == 1) || (nargin == 4)
                obj.Pulse = pulse;
            end
        end
        
        % setters
        function SetValues(self, startLocation, startValue, isStartPointApproximated, endLocation, endValue, isEndPointApproximated)

            self.StartPoint = PointInPulse(startLocation, self.Pulse.ToLocationInCell(startLocation), startValue);
            self.IsStartPointApproximated = isStartPointApproximated;
            
            self.EndPoint = PointInPulse(endLocation, self.Pulse.ToLocationInCell(endLocation), endValue);
            self.IsEndPointApproximated = isEndPointApproximated;
            
        end
        
        
        % dependent properties
        function res = get.Duration(self)
            res = self.EndPoint.Location - self.StartPoint.Location;
        end

        function res = get.Duration_ms(self)
            res = self.Duration * Sampling.Period_ms;
        end
        
    end
    
    methods (Access = protected)
        function Init(~, ~)
        end
    end
    
end

