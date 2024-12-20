% CLASS DESCRIPTION 
%
% NOTES:
%
% RELEASE VERSION: 0.6
%
% AUTHOR: Anton Shpak (a.shpak@victorchang.edu.au)
%
% DATE: February 2020
classdef UpDown < BasePulsePart
    
    properties(GetAccess = public, SetAccess = protected)
        Upstroke = Upstroke();
        Downstroke = Downstroke();
    end


    methods
        % constructor
        function obj = UpDown(pulse, upstroke, downstroke)
            
            if (nargin == 0) 
                argsBase = {};
            elseif (nargin == 3)
                argsBase{1} = pulse;
            else
                error('Wrong number of input arguments');
            end

            % Call base class constructor
            obj@BasePulsePart(argsBase{:});       
            
            if (nargin == 0) 
                obj.Upstroke = Upstroke();
                obj.Downstroke = Downstroke();
            elseif (nargin == 3)
                obj.Upstroke = upstroke;
                obj.Downstroke = downstroke;
            end
            
        end
        
    end    
    
    methods (Access = protected)
        function res = getStartPoint(self)
            res = self.Upstroke.StartPoint;
        end
        
        function res = getEndPoint(self)
            res = self.Downstroke.EndPoint;
        end
        
        function res = getPeakPoint(self)
            res = self.Upstroke.EndPoint;
        end
    end
    
    
end

