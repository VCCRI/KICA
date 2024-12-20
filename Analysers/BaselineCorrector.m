classdef BaselineCorrector
% CLASS DESCRIPTION 
%
% NOTES:
%
% RELEASE VERSION: 0.6
%
% AUTHOR: Anton Shpak (a.shpak@victorchang.edu.au)
%
% DATE: February 2020
      
    methods (Static)
        function [outValues, baseline] = CorrectBaseline(inLocations, inValues, regressionMethod)
            %showPlot = 1;
            
            % 1st step - remove any linear slope to make peakfinder working in any case
            tmpValues = detrend(inValues, 1);
            baseline = inValues - tmpValues;
            
            selRatio = 4;           %             <-- PARAM
            threshRatio = 6;        %             <-- PARAM
            extrema = 1;

            maxIterationsNumber = 10; %             <-- PARAM
            baselineFitThresholdPercentage = 8; %   <-- PARAM
            scaleFactor = 0.75;
            
            iterationsCounter = 0;
            referenceBaselineDelta = 0;
            baselineFit = false;
            
            maxNumWindows = 1000;
            
            while ((iterationsCounter < maxIterationsNumber) && (baselineFit == false))

                [peakLocations, ~] = Calc.Peaks(tmpValues, selRatio, threshRatio, extrema);

                peakDistance = mean(diff(peakLocations));

                if isnan(peakDistance)
                    peakDistance=200;
                end
                stepSize = peakDistance * scaleFactor;
                
                estimNumWindows = length(tmpValues) / stepSize;
                if estimNumWindows > maxNumWindows
                    stepSize = ceil(length(tmpValues) / (maxNumWindows + 1));
                    Log.Message(3, strcat("Baseline correction: ", " StepSize corrected as estimated number of windows exceedds maximum"));
                end
                
                try
                    % calculate the baseline
                    [tmpValues, tmpBaseline] = BaselineCorrector.CorrectBaseline_MsBackAdj(inLocations, tmpValues, regressionMethod, stepSize, 2*stepSize);
                catch ME
                    Log.ErrorMessage(3, strcat("Baseline correction error: ", " ID: ", ME.identifier, " Message: ", ME.message));
                    % log and swallow the exception
                    break
                end
                
                % validate the baseline fit against the threshold: exit if fits
                tmpBaselineDelta = max(-tmpBaseline) - min(-tmpBaseline);
                if (iterationsCounter == 0)
                    referenceBaselineDelta = tmpBaselineDelta;
                else
                    if ((tmpBaselineDelta/referenceBaselineDelta)*100 <= baselineFitThresholdPercentage)
                        baselineFit = true;
                    end
                end
                
                % calculate summary baseline
                baseline = baseline - tmpBaseline;
                
                % increment iterationsCounter
                iterationsCounter = iterationsCounter + 1;
            end
            
            outValues = tmpValues;
            
            Log.Message(3, strcat("Iterations for baseline correction: ", num2str(iterationsCounter)));
        end
    end
    
    methods (Access = private, Static = true)
        
        function [outY, outDelta] = CorrectBaseline_MsBackAdj(inX, inY, regressionMethod, stepSize, windowSize)
            
            outY = msbackadj(inX, inY, ...
                            'RegressionMethod', regressionMethod,...
                            'StepSize', stepSize,...
                            'WindowSize', windowSize,...
                            'SmoothMethod', 'none',...
                            'QuantileValue', .05,...
                            'ShowPlot', 0); % TODO: remove showPlot at all
                        
            outDelta = outY - inY;
        end
        
    end
end

