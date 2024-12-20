% CLASS DESCRIPTION 
%
% NOTES:
%
% RELEASE VERSION: 0.6
%
% AUTHOR: Anton Shpak (a.shpak@victorchang.edu.au)
%
% DATE: February 2020
classdef Point

    properties (GetAccess = public, SetAccess = public)
        Location = double.empty;
        Value = double.empty;
    end
    
    methods
        function obj = Point(location, value)
            
            if nargin == 0 % NEED THE EMPTY CONSTRUCTOR FOR ARRAY SUPPORT
                obj.Location = double.empty;
                obj.Value = double.empty;
            elseif nargin == 2
                obj.Location = location;
                obj.Value = value;
            else
                error('Wrong number of input arguments');
            end
        end
        
    end
end

