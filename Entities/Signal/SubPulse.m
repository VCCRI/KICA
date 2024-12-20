% CLASS DESCRIPTION 
%
% NOTES:
%
% RELEASE VERSION: 0.6
%
% AUTHOR: Anton Shpak (a.shpak@victorchang.edu.au)
%
% DATE: February 2020
classdef SubPulse < BasePulsePart

    properties(GetAccess = public, SetAccess = protected)
        UpDowns = UpDown.empty;
    end

    properties (Access = private)
        peakPoint = PointInPulse();
    end
    
    properties (Dependent)
        Upstroke;
    end
    
    methods
        % constructor
        function obj = SubPulse(pulse, updowns)
            
            if (nargin == 0) 
                argsBase = {};
            elseif (nargin == 2)
                argsBase{1} = pulse;
            else
                error('Wrong number of input arguments');
            end

            % Call base class constructor
            obj@BasePulsePart(argsBase{:});       
            
            if (nargin == 0) 
                obj.UpDowns = UpDown.empty;
                obj.peakPoint = PointInPulse();
            elseif (nargin == 2)
                if (isempty(updowns))
                    error('UpDowns can not be empty');
                end
                obj.UpDowns = updowns;
                obj.peakPoint = obj.FindPeakPoint();
            end
        end
        
        % Upstroke
        function res = get.Upstroke(self)
            res = self.UpDowns(1).Upstroke;
        end
        
        
    end    
    
    methods (Access = protected)

        function res = getStartPoint(self)
            res = self.UpDowns(1).StartPoint;
        end
        
        function res = getEndPoint(self)
            res = self.UpDowns(end).EndPoint;
        end
        
        function res = getPeakPoint(self)
            res = self.peakPoint;
        end
        
    end
    
    methods (Access = private)
        
        function res = FindPeakPoint(self)
            maximum = realmin;
            for i = 1 : length(self.UpDowns)
                if (self.UpDowns(i).PeakPoint.Value > maximum)
                    maximum = self.UpDowns(i).PeakPoint.Value;
                    res = self.UpDowns(i).PeakPoint;
                end
            end
        end
        
    end
    
end

