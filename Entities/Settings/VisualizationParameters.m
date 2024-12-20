% CLASS DESCRIPTION 
%
% NOTES:
%
% RELEASE VERSION: 0.6
%
% AUTHOR: Anton Shpak (a.shpak@victorchang.edu.au)
%
% DATE: February 2020
classdef VisualizationParameters < handle
    
    properties (SetAccess = private, GetAccess = public)

        ShowVisualizedCells = false;
        SaveVisualizedCellsToFiles = false;
        
    end
    
    methods
        function obj = VisualizationParameters(showVisualizedCells, saveVisualizedCellsToFiles)
            if (nargin == 0)
                obj.ShowVisualizedCells = false; 
                obj.SaveVisualizedCellsToFiles = false;
            elseif (nargin == 2)
                obj.ShowVisualizedCells = showVisualizedCells; 
                obj.SaveVisualizedCellsToFiles = saveVisualizedCellsToFiles;
            else
                error('Wrong number of input arguments');
            end
        end
        
    end
end

