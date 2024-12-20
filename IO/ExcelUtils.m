% CLASS DESCRIPTION 
%
% NOTES:
%
% RELEASE VERSION: 0.6
%
% AUTHOR: Anton Shpak (a.shpak@victorchang.edu.au)
%
% DATE: February 2020
classdef ExcelUtils
   
    methods (Static)
        
        function [e, ewb] = OpenExcelActiveXAndWorkbook(fileName)
        % options to fix not finalized excel process after writetable():
        % 1. clear all
        % 2. system('taskkill /F /IM EXCEL.EXE');
        % 3. http://undocumentedmatlab.com/articles/fixing-matlabs-actxserver <-- use this
            
            try
                %try
                %    % Try to reuse an existing COM server instance if possible
                %    e = actxGetRunningServer('excel.application');
                %catch
                %    % Never mind - continue normally to start the COM server and connect to it
                %    e = actxserver('excel.application');
                %end                
                e = actxserver('excel.application');
            catch ME
                Log.ErrorMessage(1, strcat("Failed to open Excel ActiveX server"));
                ex = MException(Error.ID_WriteFileError, strcat(Error.Msg_OpenExcelServerError, '\r', ME.identifier, "\r", ME.message));
                throw(ex);
            end
            
            try
                ewb = e.Workbooks.Open(fileName); % provide full path!
            catch ME
                Quit(e);
                delete(e);
               
                Log.ErrorMessage(1, strcat("Failed to open Excel Worksheets in file: '", fileName, "'"));
                ex = MException(Error.ID_WriteFileError, strcat(Error.Msg_OpenExcelWorksheetsError, '\r', ME.identifier, "\r", ME.message));
                throw(ex);
            end
            
        end
        
        function CloseExcelActiveXAndWorkbook(e, ewb)
            try
                ewb.Close(false);
            catch ME
                Log.ErrorMessage(1, strcat("Failed to close Excel Worksheets"));
                ex = MException(Error.ID_WriteFileError, strcat(Error.Msg_CloseExcelWorksheetsError, '\r', ME.identifier, "\r", ME.message));
                throw(ex);
            end
            
            try
                Quit(e);
                delete(e);
            catch ME
                Log.ErrorMessage(1, strcat("Failed to close Excel ActiveX server"));
                ex = MException(Error.ID_WriteFileError, strcat(Error.Msg_CloseExcelServerError, '\r', ME.identifier, "\r", ME.message));
                throw(ex);
            end
            
        end
        
        function RenameWorkheetsInExcelFile(ewb, worksheetIndexes, worksheetNames)

            fileName = FileWriter.CorrectFileName(strcat(ewb.Path, "\", ewb.Name));
            
            if (exist(fileName, 'file') ~= 2)
                throw(MException(Error.ID_WriteFileError, strcat(Error.Msg_WriteFileError_NotExist, " ", fileName)));
            end
            
            if (length(worksheetIndexes) ~= length(worksheetNames))
                throw(MException(Error.ID_WriteFileError, strcat(Error.Msg_WriteFileRenameWorksheetsError, " ", fileName)));
            end

            try
                for i = 1 : length(worksheetIndexes)
                    ewb.Worksheets.Item(worksheetIndexes(i)).Name = worksheetNames(i); 
                end
                %ewb.Save;
                
            catch ME
                % as there is no 'finally' block in matlab, 
                % close workbooks and exit ActiveX here
                %FileWriter.CloseAndQuitExcel(e, ewb);
                ex = MException(Error.ID_WriteFileError, strcat(Error.Msg_WriteFileRenameWorksheetsError, '\r', ME.identifier, "\r", ME.message));
                throw(ex);
            end
        end
        
    end
end
