classdef WellAnalyser < handle
% CLASS DESCRIPTION 
%
% NOTES:
%
% RELEASE VERSION: 0.6
%
% AUTHOR: Anton Shpak (a.shpak@victorchang.edu.au)
%
% DATE: February 2020

    
    properties (GetAccess = public, SetAccess = protected)
        
        Well = Well();
        
    end
    
    methods
        
        % constructor
        function obj = WellAnalyser(table)
            obj.Well = Well(table);
        end
                

        function StartAnalysis(self)
            
            cellsNumber = length(self.Well.Cells);
            
            if (cellsNumber > 0)
                
                startCellsAnalysis = Log.StartBlock(1, strcat("Started analysis of ", num2str(cellsNumber), " cells"));
                for i = 1 : cellsNumber
                    cellAnalyser = CellAnalyser(self.Well.Cells(i));
                    cellAnalyser.StartAnalysis();
                end
                Log.EndBlock(startCellsAnalysis, 1, strcat("Finished analysis of ", num2str(cellsNumber), " cells"));

                fileWriter = FileWriter(self.Well);
                fileWriter.WriteWellAnalysisResults();
                
            end
            
        end
        
        
    end
        
end

