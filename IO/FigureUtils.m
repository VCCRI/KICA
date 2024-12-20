% CLASS DESCRIPTION 
%
% NOTES:
%
% RELEASE VERSION: 0.6
%
% AUTHORS: Satya Arjunan (s.arjunan@victorchang.edu.au)
%          Anton Shpak (a.shpak@victorchang.edu.au)
%
% DATE: February 2020
classdef FigureUtils
   
    methods (Static)

        function CopyFigureToClipboard(hFigure)
            
            % remember legend visible
            hLegend = findobj(hFigure, 'Type', 'Legend');
            isLegendVisible = get(hLegend, 'Visible');
            if (isLegendVisible)
                set(hLegend, 'Visible', 'off');
            end

            % remember renderer
            r = get(hFigure, 'Renderer');
            
            set(hFigure, 'Renderer', 'Painters');
            drawnow
            
            startExport = Log.StartBlock(5, strcat("Started figure export"));
            % copy figure to clipboard
            hgexport(hFigure, '-clipboard');
            Log.EndBlock(startExport, 5, strcat("Finished figure export"), 1);
            
            % set back renderer
            set(hFigure, 'Renderer', r); 

            % set back legend visible
            if (isLegendVisible)
                set(hLegend, 'Visible', 'on');
            end
        end

        function SaveFigureToFile(figure, fileName)
            
            try
                saveas(figure, fileName, 'fig');
                
            catch ME
                ex = MException(Error.ID_SaveFigureError, strcat(Error.Msg_SaveFigureError, '\r', ME.identifier, "\r", ME.message));
                throw(ex);
            end
                
        end        
    
    end
    
end

