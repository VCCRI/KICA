classdef QCStatus < uint32
% CLASS DESCRIPTION: 
% Contains Status of Quality Control
%
% NOTES:
%
% RELEASE VERSION: 0.6
%
% AUTHOR: Anton Shpak (a.shpak@victorchang.edu.au)
%
% DATE: February 2020  

    enumeration
        QC_NotPerformed (0)
        QC_OK (1)
        QC_Failed_CheckForSNR (2)
        QC_Failed_CheckForPulsesMissingStimuli (4)
        QC_Failed_CheckForPulsesSpanMoreThanOneStimilus (8)
        QC_Failed_CheckForNoPulsesDetected (16)
    end
    
    methods (Static)
        function res = ToString(qcStatus)
            res = "";

            if (qcStatus == QCStatus.QC_NotPerformed)
                res = QCStatus.AddStatusToString(res, QCStatus.QC_NotPerformed);
            end

            if (bitand(qcStatus, QCStatus.QC_OK))
                res = QCStatus.AddStatusToString(res, QCStatus.QC_OK);
            end
            
            if (bitand(qcStatus, QCStatus.QC_Failed_CheckForSNR))
                res = QCStatus.AddStatusToString(res, QCStatus.QC_Failed_CheckForSNR);
            end

            if (bitand(qcStatus, QCStatus.QC_Failed_CheckForNoPulsesDetected ))
                res = QCStatus.AddStatusToString(res, QCStatus.QC_Failed_CheckForNoPulsesDetected);
            end
            
            if (bitand(qcStatus, QCStatus.QC_Failed_CheckForPulsesMissingStimuli))
                res = QCStatus.AddStatusToString(res, QCStatus.QC_Failed_CheckForPulsesMissingStimuli);
            end
            
            if (bitand(qcStatus, QCStatus.QC_Failed_CheckForPulsesSpanMoreThanOneStimilus))
                res = QCStatus.AddStatusToString(res, QCStatus.QC_Failed_CheckForPulsesSpanMoreThanOneStimilus);
            end
        end
    end
    
    methods (Static, Access = private)
        function res = AddStatusToString(str, qcStatus)
            
            res = str;
            
            if (~eq(res, ""))
                res = strcat(res, ", ");
            end
            res = strcat(res, string(qcStatus));
            
        end
    end
    
end

