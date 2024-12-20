% CLASS DESCRIPTION 
%
% NOTES:
%
% RELEASE VERSION: 0.6
%
% AUTHOR: Anton Shpak (a.shpak@victorchang.edu.au)
%
% DATE: February 2020
classdef PointInPulse < Point

    properties (GetAccess = public, SetAccess = public)
        LocationInCell = double.empty;
    end
    
    methods
        function obj = PointInPulse(locationInPulse, locationInCell, value)
            
            if nargin == 0 
                argsBase = {};
            elseif (nargin == 3)
                argsBase{1} = locationInPulse;
                argsBase{2} = value;
            else
                error('Wrong number of input arguments');
            end
            
            % Call base class constructor
            obj@Point(argsBase{:});       

            if (nargin == 3)
                obj.LocationInCell = locationInCell;
            end
        end
        
    end
end
