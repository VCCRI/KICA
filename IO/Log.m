% CLASS DESCRIPTION 
%
% NOTES:
%
% RELEASE VERSION: 0.6
%
% AUTHOR: Anton Shpak (a.shpak@victorchang.edu.au)
%
% DATE: February 2020
classdef Log
    
    methods (Static, Access = public)
        
        function startTime = StartBlock(level, text)
            
            startTime = tic;
            
            % indentation
            if (level > 0)
                for i = 1 : level
                    text = strcat("\t", text);
                end
            end
            
            % end of line
            text = strcat(text, "\n");
            
            fprintf(text);
        end
        
        function endTime = EndBlock(startTime, level, text, numberOfEmptyLinesAfter)
            
            endTime = toc(startTime);
            
            if (nargin == 3)
                numberOfEmptyLinesAfter = 2;
            end

            % indentation
            if (level > 0)
                for i = 1 : level
                    text = strcat("\t", text);
                end
            end
            
            text = strcat(text, " in ", num2str(endTime), " s");
            
            % end of block
            for i = 1 : numberOfEmptyLinesAfter
                text = strcat(text, "\n");
            end
            
            fprintf(text);
            
        end

        function Message(level, text)
            
            % Tab
            if (level > 0)
                for i = 1 : level
                    text = strcat("\t", text);
                end
            end
            
            % end of line
            text = strcat(text, "\n");
            
            fprintf(text);
        end
        
        function ErrorMessage(level, text)
            
            % Tab
            if (level > 0)
                for i = 1 : level
                    text = strcat("\t", text);
                end
            end
            
            % end of line
            text = strcat(text, "\n\n");
            
            fprintf(2, text);
        end
        
    end
    
end