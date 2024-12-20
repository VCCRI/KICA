% CLASS DESCRIPTION 
%
% NOTES:
%
% RELEASE VERSION: 0.6
%
% AUTHOR: Anton Shpak (a.shpak@victorchang.edu.au)
%
% DATE: February 2020
classdef FileReader
    
    properties (Constant)
        Table_VariableName_CellID_Prefix = "CellID_";
    end
    
    methods (Static)

        function fileFullName = SelectDataFile()
            fileFullName = "";
            
            % open file dialog
            [file, path, ~] = uigetfile('*.csv', 'Select a *.csv Data File');
            if (~isequal(file, 0))
                doubleFileSep = strcat(filesep, filesep);
                fileFullName = strrep(strrep(string(fullfile(path, file)), doubleFileSep, filesep), filesep, doubleFileSep);

                [~, ~, fileExt] = fileparts(fileFullName);
                if (~isequal(fileExt, ".csv"))
                    Log.ErrorMessage(0, "Error: Please, select a *.csv file");
                    fileFullName = "";
                end
            end
            
        end
        
        function T = ReadFileToTable(fileFullName)
            
            if (exist(fileFullName, 'file') ~= 2)
                throw(MException(Error.ID_ReadFileError, strcat(Error.Msg_ReadFileError_NotExist, " ", fileFullName)));
            end
            
            try
                startReadFile = Log.StartBlock(1, strcat("Started reading file '", fileFullName, "'"));
                
                % read whole file to detect number of cells in the file
                opts = detectImportOptions(fileFullName);
                opts.Delimiter = ',';
                opts = setvartype(opts, 'char');
                opts = setvaropts(opts, 'FillValue', '');
                opts.DataLines = [1 Inf];
                opts.EmptyLineRule = 'read'; 

                T1 = readtable(fileFullName, opts);

                % set default date and description
                date = datetime("now");
                date.Format = 'MMMM d yyyy HH:mm:ss';
                [filepath,description,ext] = fileparts(fileFullName);

                % detect header row
                version = "unknown";
                headerRowIndex = 0;
                while(headerRowIndex < size(T1, 1))
                    headerRowIndex = headerRowIndex + 1;
                    if (string(table2cell(T1(headerRowIndex, 1))) == "Time (ms)")
                        version = 'generic';
                        break;
                    end

                    if (string(table2cell(T1(headerRowIndex, 1))) == "id" &&...
                        string(table2cell(T1(headerRowIndex, 2))) == "T (index)" &&...
                        string(table2cell(T1(headerRowIndex, 3))) == "T (msec)")
                        version = 'CyteSeer 3.0.0.1';
                        break;
                    end
                    second = char(table2cell(T1(headerRowIndex, 2))); % second column header
                    third = char(table2cell(T1(headerRowIndex, 3)));  % third column header
                    if (string(table2cell(T1(headerRowIndex, 1))) == "id" &&...
                        size(second,2) >= 9 &&...
                        size(third,2) >= 9)
                        if (string(second(1:9)) == "Cell ID: " && string(third(1:9)) == "Cell ID: ")
                            version = "CyteSeer 3.0.1.0";
                            break;
                        end
                    end
                end

                % if header row not found - return empty table
                if (version == "unknown" || headerRowIndex == size(T1, 1))
                    version
                    T = array2table(zeros(0, 1));
                    return;
                end

                % read second part of the file
                opts = detectImportOptions(fileFullName, 'NumHeaderLines', headerRowIndex - 1, 'ReadVariableNames', true);
                opts = setvartype(opts, 'double');
                opts = setvaropts(opts, 'FillValue', NaN);
                opts.VariableNamesLine = headerRowIndex;
                opts.DataLines = [headerRowIndex + 1 Inf];

                T = readtable(fileFullName, opts);

                if (version == "CyteSeer 3.0.0.1")
                    T = removevars(T, {'id'}); % drop "id" column
                    T = removevars(T, {'T_index_'}); % drop "T_index_" column
                elseif (version == "CyteSeer 3.0.1.0")
                    T.Properties.VariableNames{2} = 'T_msec_';
                    T = removevars(T, {'id'}); % drop "id" column
                    % drop redundant timeseries columns in the newer version
                    idx = 3:2:size(T, 2);
                    T(:,idx) = [];
                end

                if (version ~= "generic")
                    date = datetime(string(table2cell(T1(2, 2))), 'InputFormat', 'MMMM dd yyyy HH:mm:ss');
                    description = string(table2cell(T1(3, 2)));
                end

                % replace VariableNames (i.e. Cell's Column Names with
                % prefix + ID: "CellID_" + cellID (example: CellID_33)
                for i = 2 : size(T, 2)
                    cellName = T.Properties.VariableNames{i};
                    strCellIDs = regexp(cellName, '\d*', 'match');
                    cellID = num2str(10000 + i);
                    if (~isempty(strCellIDs))
                        cellID = strCellIDs(1);
                    end
                    T.Properties.VariableNames{i} = char(cellstr(strcat(FileReader.Table_VariableName_CellID_Prefix, cellID)));
                end
                % add custom properties
                T = addprop(T, {'Date','Description', 'FileFullName'},{'table', 'table', 'table'});
                T.Properties.CustomProperties.Date = date;
                T.Properties.CustomProperties.Description = description;
                
                T.Properties.CustomProperties.FileFullName = fileFullName;
                
                Log.EndBlock(startReadFile, 1, strcat("Finished reading file '", fileFullName, "'"));
                
            catch ME
                Log.ErrorMessage(1, strcat("Failed to read file '", fileFullName, "'"));
                
                ex = MException(Error.ID_ReadFileError, strcat(Error.Msg_ReadFileError, '\r', ME.identifier, "\r", ME.message));
                throw(ex);
            end
        end
        
    end
end

