% CLASS DESCRIPTION 
%
% NOTES:
%
% RELEASE VERSION: 0.6
%
% AUTHOR: Anton Shpak (a.shpak@victorchang.edu.au)
%
% DATE: February 2020
classdef Well < BaseEntity

    properties
        Cells = Cell.empty;
    end
    
    properties (GetAccess = public, SetAccess = protected)
        Date;
        FileFullName;
    end
    
    properties (Dependent)
        FileName;
        FilePath;
        FileExt;
    end


    methods
        
        % constructor
        function obj = Well(table)
            % create base class constructor arguments
            if nargin == 0 % NEED THE EMPTY CONSTRUCTOR FOR ARRAY SUPPORT
                obj.Cells = Cell.empty;
            elseif nargin == 1
                obj.Init(table);
            else
                error('Wrong number of input arguments')
            end
        end
        
    end
    
    methods (Access = protected)

        function Init(self, table)
            % TODO - validation
            
            self.Cells = Cell.empty;
            
            self.Date = table.Properties.CustomProperties.Date;
            self.Description = table.Properties.CustomProperties.Description;
            self.FileFullName = table.Properties.CustomProperties.FileFullName;
            
            times = table2array(table(:, 1));
            
            rows = size(table, 1);
            cols = size(table, 2);
                        
            for i = 2 : cols
                
                cellRaw = table2array(table(:, i));

                % TODO: move from here to a more appropriate place (i.e.
                % Cell or WellAnalyser of CellAnalyser)
                numberOfSamplesToIgnore = Parameters.PulseDetection.NumberOfSamplesAtStartToIgnore;
                if (numberOfSamplesToIgnore > 0)
                    cellRaw(1 : numberOfSamplesToIgnore) = cellRaw(numberOfSamplesToIgnore); %mean(cellRaw(numberOfSamplesToIgnore : end));
                end
                
                cellName = table.Properties.VariableNames{i};
                strCellID = erase(cellName, FileReader.Table_VariableName_CellID_Prefix);

                self.Cells(i-1, 1) = Cell(str2double(strCellID), cellName, "", times, cellRaw); 
            end
        end
    end
    
    methods

        % dependency properties
        function fileName = get.FileName(self)
            [~, fileName, ~] = fileparts(self.FileFullName);
        end

        function filePath = get.FilePath(self)
            [filePath, ~, ~] = fileparts(self.FileFullName);
        end

        % returns file extension with dot prefix: '.csv'
        function fileExt = get.FileExt(self)
            [~, ~, fileExt] = fileparts(self.FileFullName);
        end

    end
    
end

