% CLASS DESCRIPTION
% Reads data files and applies initial time window filtering.
%
% NOTES:
% Handles different CSV formats (generic, CyteSeer).
%
% RELEASE VERSION: 0.7 (Added time window filtering)
%
% AUTHOR: Anton Shpak (a.shpak@victorchang.edu.au)
%         Satya Arjunan (s.arjunan@victorchang.edu.au)
%
% DATE: March 2024

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

        function T = ReadFileToTable(fileFullName, analysisStart_ms, analysisEnd_ms)

            if (exist(fileFullName, 'file') ~= 2)
                throw(MException(Error.ID_ReadFileError, strcat(Error.Msg_ReadFileError_NotExist, " ", fileFullName)));
            end

            T = table.empty(); % Initialize T as an empty table

            try
                startReadFile = Log.StartBlock(1, strcat("Started reading file '", fileFullName, "'"));

                % read whole file to detect number of cells in the file
                opts_detect = detectImportOptions(fileFullName);
                opts_detect.Delimiter = ',';
                opts_detect = setvartype(opts_detect, 'char');
                opts_detect = setvaropts(opts_detect, 'FillValue', '');
                opts_detect.DataLines = [1 Inf];
                opts_detect.EmptyLineRule = 'read';

                T1 = readtable(fileFullName, opts_detect);

                % set default date and description
                date = datetime("now");
                date.Format = 'MMMM d yyyy HH:mm:ss';
                [~,description,~] = fileparts(fileFullName); % Use ~ to ignore unused outputs

                % detect header row
                version = "unknown";
                headerRowIndex = 0;
                while(headerRowIndex < size(T1, 1))
                    headerRowIndex = headerRowIndex + 1;
                    firstColHeader = string(table2cell(T1(headerRowIndex, 1)));

                    if (firstColHeader == "Time (ms)")
                        version = 'generic';
                        break;
                    end

                    % Check for CyteSeer 3.0.0.1
                    if (headerRowIndex + 1 <= size(T1, 1)) % Ensure next row exists
                        secondColHeader = string(table2cell(T1(headerRowIndex, 2)));
                        thirdColHeader = string(table2cell(T1(headerRowIndex, 3)));
                        if (firstColHeader == "id" &&...
                            secondColHeader == "T (index)" &&...
                            thirdColHeader == "T (msec)")
                            version = 'CyteSeer 3.0.0.1';
                            break;
                        end
                    end

                    % Check for CyteSeer 3.0.1.0 (handles potential missing columns safely)
                     if size(T1, 2) >= 3 % Ensure at least 3 columns exist
                         second = char(table2cell(T1(headerRowIndex, 2))); % second column header
                         third = char(table2cell(T1(headerRowIndex, 3)));  % third column header
                         if (firstColHeader == "id" &&...
                             size(second,2) >= 9 &&...
                             size(third,2) >= 9)
                             if (string(second(1:9)) == "Cell ID: " && string(third(1:9)) == "Cell ID: ")
                                 version = "CyteSeer 3.0.1.0";
                                 break;
                             end
                         end
                     end
                end

                % if header row not found - return empty table
                if (version == "unknown" || headerRowIndex == size(T1, 1))
                    Log.ErrorMessage(1, strcat("Could not determine file version or find header row in '", fileFullName, "'. Returning empty table."));
                    T = table.empty(); % Ensure T is empty
                    Log.EndBlock(startReadFile, 1, strcat("Finished reading file (failed header detection) '", fileFullName, "'"));
                    return;
                end

                % read second part of the file
                opts = detectImportOptions(fileFullName, 'NumHeaderLines', headerRowIndex, 'ReadVariableNames', true); % Use headerRowIndex directly
                opts = setvartype(opts, 'double');
                opts = setvaropts(opts, 'FillValue', NaN);
                opts.VariableNamesLine = headerRowIndex;
                opts.DataLines = [headerRowIndex + 1 Inf];

                T = readtable(fileFullName, opts);

                if (version == "CyteSeer 3.0.0.1")
                    T = removevars(T, {'id'}); % drop "id" column
                    T = removevars(T, {'T_index_'}); % drop "T_index_" column
                     % Ensure the time column is named correctly for consistency
                     if ismember('T_msec_', T.Properties.VariableNames)
                        T.Properties.VariableNames{'T_msec_'} = 'Time_ms_';
                     end
                elseif (version == "CyteSeer 3.0.1.0")
                    % Safely rename if the column exists
                    if ismember('T_msec_', T.Properties.VariableNames)
                        T.Properties.VariableNames{'T_msec_'} = 'Time_ms_';
                    elseif ismember('T__msec_', T.Properties.VariableNames) % Handle potential double underscore
                         T.Properties.VariableNames{'T__msec_'} = 'Time_ms_';
                    end
                    T = removevars(T, {'id'}); % drop "id" column
                    % drop redundant timeseries columns in the newer version
                    % Find columns that start with 'Time_ms_' followed by a number
                    redundantTimeCols = startsWith(T.Properties.VariableNames, 'Time_ms_') & ~strcmp(T.Properties.VariableNames, 'Time_ms_');
                    T(:, redundantTimeCols) = [];
                elseif (version == "generic")
                     % Ensure the first column is consistently named 'Time_ms_'
                    if ~isempty(T.Properties.VariableNames) && ~strcmp(T.Properties.VariableNames{1}, 'Time_ms_')
                         T.Properties.VariableNames{1} = 'Time_ms_';
                    end
                end

                % Read metadata for CyteSeer versions
                if (version ~= "generic")
                     try
                         metaDateStr = string(table2cell(T1(2, 2)));
                         date = datetime(metaDateStr, 'InputFormat', 'MMMM dd yyyy HH:mm:ss');
                     catch ME_date
                         Log.ErrorMessage(2, ['FileReader: Could not parse date string "', metaDateStr, '". Using current datetime. Error: ', ME_date.message]);
                         date = datetime("now"); % Fallback
                         date.Format = 'MMMM d yyyy HH:mm:ss';
                     end
                     description = string(table2cell(T1(3, 2)));
                end

                % replace VariableNames (i.e. Cell's Column Names with prefix + ID)
                for i = 2 : size(T, 2)
                    cellName = T.Properties.VariableNames{i};
                    % Use regex to find the *last* number in the string, more robust
                    strCellIDs = regexp(cellName, '\d+$', 'match');
                    cellID = num2str(10000 + i); % Default if no number found
                    if (~isempty(strCellIDs))
                        cellID = strCellIDs{1}; % Use the found trailing number
                    else
                        Log.Message(2, sprintf("FileReader: Could not extract numeric ID from column '%s'. Using default ID %d.", cellName, str2double(cellID)));
                    end
                    T.Properties.VariableNames{i} = char(strcat(FileReader.Table_VariableName_CellID_Prefix, cellID));
                end

                 % Rename the time column consistently *after* potential renaming above
                 if ~isempty(T.Properties.VariableNames) && ~strcmp(T.Properties.VariableNames{1}, 'Time_ms_')
                     T.Properties.VariableNames{1} = 'Time_ms_';
                 end


                % add custom properties
                T = addprop(T, {'Date','Description', 'FileFullName'},{'table', 'table', 'table'});
                T.Properties.CustomProperties.Date = date;
                T.Properties.CustomProperties.Description = description;
                T.Properties.CustomProperties.FileFullName = fileFullName;


                % --- START: Time Window Filtering ---
                % Check if the table is not empty before attempting to filter
                if ~isempty(T) && height(T) > 0
                    % Ensure the time column name is correct
                    timeColumnName = T.Properties.VariableNames{1};
                    if ~strcmp(timeColumnName, 'Time_ms_')
                         Log.ErrorMessage(1, sprintf("FileReader: Expected time column name 'Time_ms_' but found '%s'. Cannot filter by time.", timeColumnName));
                    else
                        timeValues = T.(timeColumnName); % Extract time values
                        originalRowCount = height(T);

                        % Create logical index for the time window
                        timeMask = (timeValues >= analysisStart_ms) & (timeValues <= analysisEnd_ms);

                        % Apply the filter
                        T = T(timeMask, :);

                        % Check if any data remains after filtering
                        if height(T) == 0
                             Log.ErrorMessage(1, sprintf("FileReader: No data points found within the specified time window [%.2f ms, %.2f ms]. Returning empty table.", analysisStart_ms, analysisEnd_ms));
                             % Keep T as an empty table with original columns if desired
                             % T = table('Size',[0 size(T,2)],'VariableTypes',varfun(@class,T,'OutputFormat','cell'),'VariableNames',T.Properties.VariableNames);
                             % Or just let it be empty table as created initially
                        else
                            Log.Message(2, sprintf("FileReader: Filtered data to time window [%.2f ms, %.2f ms]. Kept %d out of %d original data points.", analysisStart_ms, analysisEnd_ms, height(T), originalRowCount));
                        end
                    end
                else
                     Log.Message(2, "FileReader: Input table was empty before time filtering.");
                     % T is already empty, nothing to do.
                end
                % --- END: Time Window Filtering ---


                Log.EndBlock(startReadFile, 1, strcat("Finished reading file '", fileFullName, "'"));

            catch ME
                Log.ErrorMessage(1, strcat("Failed to read file '", fileFullName, "'. Error ID: ", ME.identifier, " Message: ", ME.message));
                T = table.empty(); % Ensure T is empty on error
                % Consider rethrowing if the calling function should handle it
                % ex = MException(Error.ID_ReadFileError, strcat(Error.Msg_ReadFileError, '\r', ME.identifier, "\r", ME.message));
                % throw(ex);
            end
        end

    end
end
