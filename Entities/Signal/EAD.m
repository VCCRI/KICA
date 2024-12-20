% CLASS DESCRIPTION 
%
% NOTES:
%
% RELEASE VERSION: 0.6
%
% AUTHOR: Anton Shpak (a.shpak@victorchang.edu.au)
%
% DATE: February 2020
classdef EAD

    properties
        EADPoint; % DataPoint ??
    end
    
    methods
        function obj = EAD()
            obj.EADPoint = libpointer;
        end
        
    end
end

