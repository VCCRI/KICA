classdef Error
% CLASS DESCRIPTION: 
% Contains Exception IDs and Messages
%
% NOTES:
%
% RELEASE VERSION: 0.6
%
% AUTHOR: Anton Shpak (a.shpak@victorchang.edu.au)
%
% DATE: February 2020
properties (Constant)
        ID_ReadFileError = "KIC_DAT:FileReadError";
        Msg_ReadFileError = "Error reading data file:";
        Msg_ReadFileError_NotExist = "File does not exist: ";
        
        ID_WriteFileError = "KIC_DAT:FileWriteError";
        Msg_WriteFileError = "Error writing data to file:"
        Msg_WriteFileRenameWorksheetsError = "Error renaming Worksheets in file:"
        Msg_WriteFileError_NotExist = "File does not exist: ";
        Msg_OpenExcelServerError = "Error opening Excel ActiveX Server";
        Msg_OpenExcelWorksheetsError = "Error opening Excel Worksheets from file: ";
        Msg_CloseExcelWorksheetsError = "Error closing Excel Worksheets from file: ";
        Msg_CloseExcelServerError = "Error closing Excel ActiveX Server";
        Msg_WriteFifuresToFileError = "Error writing figures to file:"
        
        ID_SaveFigureError = "KIC_DAT:FigureSaveError";
        Msg_SaveFigureError = "Error saving figure to file:"
       
        
        ID_CellAnalyser_DetectPulsesError = "KIC_DAT:DetectPulsesError";
        Msg_CellAnalyser_DetectPulsesError_EdgesDontMatch = "Edges do not match:";
    
    end
end

