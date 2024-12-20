% CLASS DESCRIPTION: 
% Static class, contains utilites for vizualisation
%
% NOTES:
%
% RELEASE VERSION: 0.6
%
% AUTHOR: Anton Shpak (a.shpak@victorchang.edu.au)
%
% DATE: February 2020

classdef Visualiser
    
    methods (Static)

        function fig = GetFigureForPulseDetection(cell, visibleOnOff)
           
            startCreateFigurePulseDetection = Log.StartBlock(4, strcat("Started creating Visualization of Pulse Detection for Cell_ID: ", num2str(cell.ID)));
            
            clrRawSignal = Color.Yellow;
            clrZeroLine = Color.Red;
            clrThresholdLine = Color.Purple;
            clrRawBaselineCorrected = Color.Green;
            clrDenoised = Color.Blue;
            clrDenoisedBaselineDelta = Color.Red;
            clrDenoisedBaselineCorrected = Color.DarkBlue;
            clrPulseFrame = Color.Red;
            clrStimuli = Color.Green;
            
            pulseLineWidth = 1;
            
            % create figure
            fig = figure('visible', visibleOnOff);
            % must set the figure 'Visible' flag to 'on' when the figure is created,
            % otherwise it won't show up
            set(gcf, 'CreateFcn', @(src, event) set(src ,'Visible', 'on'));

            nonCorrectedDelta = min(cell.RawBaselineDelta) - max(cell.RawBaselineCorrected);
            
            X = linspace(1, length(cell.Times), length(cell.Times));
            
            % plot raw signal
            hRawSignal = plot(X, cell.Raw - nonCorrectedDelta, 'Color', clrRawSignal, 'LineWidth', 1);
            %hRawSignal = plot(cell.Raw, 'Color', clrRawSignal, 'LineWidth', 1);
            hold on;

            % plot zero line
            hZeroLine = line(xlim, [0 0], 'Color', clrZeroLine, 'LineWidth', 1);

            % plot threshold line
            hThresholdLine = line(xlim, [cell.PulseDetectionThresholdValue cell.PulseDetectionThresholdValue], 'Color', clrThresholdLine, 'LineWidth', 1);

            % plot raw baseline corrected signal
            hRawBaselineCorrected = plot(cell.RawBaselineCorrected, 'Color', clrRawBaselineCorrected, 'LineWidth', 1);

            % plot denoised signal
            hDenoised = plot(cell.Denoised - nonCorrectedDelta, 'Color', clrDenoised, 'LineWidth', 2);
            hDenoisedBaselineDelta = plot(cell.DenoisedBaselineDelta - nonCorrectedDelta, 'Color', clrDenoisedBaselineDelta, 'LineWidth', 2);
            hDenoisedBaselineCorrected = plot(cell.DenoisedBaselineCorrected, 'Color', clrDenoisedBaselineCorrected, 'LineWidth', 1.5);

            % plot time-based stimuli start times
            for i = 1 : Stimulation.StimuliNumber
                hStimuliStart = line([Stimulation.StimuliLocations(i) Stimulation.StimuliLocations(i)], ylim, 'Color', clrStimuli, 'LineWidth', 1);
            end
            
            % plot pulses detected
            if (cell.HasPulsesDetected)
                for i = 1 : length(cell.Pulses)
                    pulse = cell.Pulses(i);

                    hPulse = line([pulse.Start pulse.Start], [0 pulse.Max.Value], 'Color', clrPulseFrame, 'LineWidth', pulseLineWidth);
                    line([pulse.End pulse.End], [0 pulse.Max.Value], 'Color', clrPulseFrame, 'LineWidth', pulseLineWidth);

                    line([pulse.Start pulse.End], [pulse.MaxDenoised.Value pulse.MaxDenoised.Value], 'Color', clrDenoisedBaselineCorrected, 'LineWidth', pulseLineWidth+1);

                    line([pulse.Start pulse.End], [pulse.Max.Value pulse.Max.Value], 'Color', clrRawBaselineCorrected, 'LineWidth', pulseLineWidth);
                end
            end
            
            grid on;

            % build legend entires
            legendHandlers = [];
            legendLabels = [];
            legendHandlers = [legendHandlers, hRawSignal];
            legendLabels = [legendLabels, "Raw Signal"];
            legendHandlers = [legendHandlers, hRawBaselineCorrected];
            legendLabels = [legendLabels, "Raw Signal Baseline Corrected"];
            legendHandlers = [legendHandlers, hDenoised];
            legendLabels = [legendLabels, "Denoised Signal"];
            legendHandlers = [legendHandlers, hDenoisedBaselineDelta];
            legendLabels = [legendLabels, "Denoised Baseline"];
            legendHandlers = [legendHandlers, hDenoisedBaselineCorrected];
            legendLabels = [legendLabels, "Denoised Baseline Corrected"];
            if (cell.HasPulsesDetected)
                legendHandlers = [legendHandlers, hPulse];
                legendLabels = [legendLabels, "Pulses detected"];
            end
            legendHandlers = [legendHandlers, hStimuliStart];
            legendLabels = [legendLabels, "Stimuli start times"];
            legendHandlers = [legendHandlers, hZeroLine];
            legendLabels = [legendLabels, "Zero"];
            legendHandlers = [legendHandlers, hThresholdLine];
            legendLabels = [legendLabels, convertContainedStringsToChars(strcat("Threshold ", num2str(Parameters.PulseDetection.ThresholdPercentage), "%"))];
            
            % show legend
            legend(legendHandlers, legendLabels);

            % title
            title(cell.TitleFigurePulseDetection);
            
            Log.EndBlock(startCreateFigurePulseDetection, 4, strcat("Finished creating Visualization of Pulse Detection for Cell_ID: ", num2str(cell.ID)));
        end        
        
        function fig = GetFigureForPulseAnalysis(cell, visibleOnOff)
           
            startCreateFigurePulseAnalysis = Log.StartBlock(4, strcat("Started creating Visualization of Pulse Analysis for Cell_ID: ", num2str(cell.ID)));
            
            clrZeroLine = Color.Red;
            clrThresholdLine = Color.Purple;
            clrRawBaselineCorrected = Color.LightGreen;
            clrDenoisedBaselineCorrected = Color.Blue;
            clrPulseFrame = Color.Red;
            clrUpstrokeVelocity = Color.Orange;
            clrActivationTime = Color.DarkYellow;
            clrMaxUpstrokeVelocityPoint = 'g';
            clrAPDs = Color.Black;
            clrRiseFall_10_90 = Color.Purple;
            clrStimuli = Color.Green;
            
            % create figure
            fig = figure('visible', visibleOnOff);
            % must set the figure 'Visible' flag to 'on' when the figure is created,
            % otherwise it won't show up
            set(gcf, 'CreateFcn', @(src, event) set(src ,'Visible', 'on'));
            
            legendHandlers = [];
            legendLabels = [];

            % plot raw baseline corrected signal
            hRawBaselineCorrected = plot(cell.RawBaselineCorrected, 'Color', clrRawBaselineCorrected, 'LineWidth', 0.5);
            
            hold on;

            % plot time-based stimuli start times
            for i = 1 : Stimulation.StimuliNumber
                hStimuliStart = line([Stimulation.StimuliLocations(i) Stimulation.StimuliLocations(i)], ylim, 'Color', clrStimuli);
            end
            
            % plot zero line
            hZeroLine = line(xlim, [0 0], 'Color', clrZeroLine);

            % plot threshold line
            hThresholdLine = line(xlim, [cell.PulseDetectionThresholdValue cell.PulseDetectionThresholdValue], 'Color', clrThresholdLine);

            % plot the Denoised and Baseline-corrected signal
            hDenoisedBaselineCorrected = plot(cell.DenoisedBaselineCorrected, 'Color', clrDenoisedBaselineCorrected, 'LineWidth', 1.5);
            
            %plot(cell.DenoisedBaselineCorrected_dFdt, 'Color', Color.Yellow, 'LineWidth', 1);
            
            % plot pulses detected
            pulseLineWidth = 1;
            strAPDs = " ";
            
            if (cell.HasPulsesDetected)
                for i = 1 : length(cell.Pulses)
                    pulse = cell.Pulses(i);

                    % plot pulse frame
                    hPulseFrame = line([pulse.Start pulse.Start], [0 pulse.UpstrokePeakPoint.Value], 'Color', clrPulseFrame, 'LineWidth', pulseLineWidth);
                    line([pulse.End pulse.End], [0 pulse.UpstrokePeakPoint.Value], 'Color', clrPulseFrame, 'LineWidth', pulseLineWidth);
                    line([pulse.Start pulse.End], [pulse.UpstrokePeakPoint.Value pulse.UpstrokePeakPoint.Value], 'Color', clrPulseFrame, 'LineWidth', pulseLineWidth);
                    %line([pulse.Start pulse.End], [pulse.Max.Value pulse.Max.Value], 'Color', clrRawBaselineCorrected, 'LineWidth', pulseLineWidth+1);

                    % Upstroke
                    % vertical left
                    line([pulse.Upstroke.StartPoint.LocationInCell  pulse.Upstroke.StartPoint.LocationInCell], [pulse.Upstroke.StartPoint.Value pulse.Upstroke.EndPoint.Value], 'Color', clrUpstrokeVelocity, 'LineStyle', '--', 'LineWidth', .5);
                    % vertical right
                    line([pulse.Upstroke.EndPoint.LocationInCell pulse.Upstroke.EndPoint.LocationInCell], [pulse.Upstroke.StartPoint.Value pulse.Upstroke.EndPoint.Value], 'Color', clrUpstrokeVelocity, 'LineStyle', '--', 'LineWidth', .5);
                    % horizontal bottom
                    line([pulse.Upstroke.StartPoint.LocationInCell pulse.Upstroke.EndPoint.LocationInCell], [pulse.Upstroke.StartPoint.Value pulse.Upstroke.StartPoint.Value], 'Color', clrUpstrokeVelocity, 'LineStyle', '--', 'LineWidth', .5);
                    % horizontal top
                    line([pulse.Upstroke.StartPoint.LocationInCell pulse.Upstroke.EndPoint.LocationInCell], [pulse.Upstroke.EndPoint.Value pulse.Upstroke.EndPoint.Value], 'Color', clrUpstrokeVelocity, 'LineStyle', '--', 'LineWidth', .5);
                    % diagonal
                    hUpstrokeVelocity = line([pulse.Upstroke.StartPoint.LocationInCell pulse.Upstroke.EndPoint.LocationInCell], [pulse.Upstroke.StartPoint.Value pulse.Upstroke.EndPoint.Value], 'Color', clrUpstrokeVelocity, 'LineWidth', 1);
                    % green marker
                    hMaxUpstrokeVelocityPoint = plot(pulse.Upstroke.MaxVelocity.LocationInCell, pulse.Denoised(pulse.Upstroke.MaxVelocity.Location), 'ko', 'MarkerFaceColor', clrMaxUpstrokeVelocityPoint, 'MarkerSize', 4);
                    % blue marker
                    %hMaxUpstrokeVelocityValue = plot(pulse.Upstroke.MaxVelocity.LocationInCell, pulse.Upstroke.MaxVelocity.Value, 'ko', 'MarkerFaceColor', clrMaxUpstrokeVelocityValue, 'MarkerSize', 4);


                    % plot Activation Time
                    % marker
                    hActivationPoint = plot(pulse.ActivationPoint.LocationInCell, pulse.ActivationPoint.Value, 'ko', 'MarkerFaceColor', clrActivationTime, 'MarkerSize', 5);
                    % line
                    hActivationTime = line([pulse.ActivationPoint.LocationInCell pulse.ActivationPoint.LocationInCell], [0 pulse.UpstrokePeakPoint.Value], 'Color', clrActivationTime, 'LineWidth', 1.5);

                    strAPDs = " ";
                    if (~isempty(pulse.APDs))
                        for j = 1 : length(pulse.APDs)
                            apd = pulse.APDs(j);
                            hAPDs = line([apd.StartPoint.LocationInCell apd.EndPoint.LocationInCell], [apd.StartPoint.Value apd.EndPoint.Value], 'Color', clrAPDs, 'LineWidth', .5, 'Marker', 'o', 'MarkerSize', 2);
                            strAPDs = strcat(strAPDs, num2str(apd.Percentage), " ");
                        end
                    end

                    strAPDs = strcat("[", strAPDs, "]");
                    
                    if (Parameters.PulseDetection.SignalType == SignalType.Calcium)
                        % Rise 10 - 90
                        % vertical lines
                        line([pulse.Rise_10_90.StartPoint.LocationInCell pulse.Rise_10_90.StartPoint.LocationInCell], [pulse.Rise_10_90.StartPoint.Value pulse.Rise_10_90.EndPoint.Value], 'Color', clrRiseFall_10_90, 'LineStyle', '--', 'LineWidth', 0.5);
                        line([pulse.Rise_10_90.EndPoint.LocationInCell pulse.Rise_10_90.EndPoint.LocationInCell], [pulse.Rise_10_90.StartPoint.Value pulse.Rise_10_90.EndPoint.Value], 'Color', clrRiseFall_10_90, 'LineStyle', '--', 'LineWidth', 0.5);
                        % horizontal lines
                        line([pulse.Rise_10_90.StartPoint.LocationInCell pulse.Rise_10_90.EndPoint.LocationInCell], [pulse.Rise_10_90.EndPoint.Value pulse.Rise_10_90.EndPoint.Value], 'Color', clrRiseFall_10_90, 'LineWidth', 1, 'Marker', '^', 'MarkerFaceColor', clrRiseFall_10_90, 'MarkerSize', 3);
                        line([pulse.Rise_10_90.StartPoint.LocationInCell pulse.Rise_10_90.EndPoint.LocationInCell], [pulse.Rise_10_90.StartPoint.Value pulse.Rise_10_90.StartPoint.Value], 'Color', clrRiseFall_10_90, 'LineStyle', '--', 'LineWidth', 0.5, 'Marker', '^', 'MarkerFaceColor', clrRiseFall_10_90, 'MarkerSize', 3);

                        % Fall 90 - 10
                        % vertical lines
                        % left
                        line([pulse.Fall_90_10.StartPoint.LocationInCell pulse.Fall_90_10.StartPoint.LocationInCell], [pulse.Fall_90_10.StartPoint.Value pulse.Fall_90_10.EndPoint.Value], 'Color', clrRiseFall_10_90, 'LineStyle', '--', 'LineWidth', 0.5);
                        % right
                        line([pulse.Fall_90_10.EndPoint.LocationInCell pulse.Fall_90_10.EndPoint.LocationInCell], [pulse.Fall_90_10.StartPoint.Value pulse.Fall_90_10.EndPoint.Value], 'Color', clrRiseFall_10_90, 'LineStyle', '--', 'LineWidth', 0.5);
                        % horizontal lines
                        % top
                        line([pulse.Fall_90_10.StartPoint.LocationInCell pulse.Fall_90_10.EndPoint.LocationInCell], [pulse.Fall_90_10.StartPoint.Value pulse.Fall_90_10.StartPoint.Value], 'Color', clrRiseFall_10_90, 'LineWidth', 1, 'Marker', 'v', 'MarkerFaceColor', clrRiseFall_10_90, 'MarkerSize', 3);
                        % bottom
                        line([pulse.Fall_90_10.StartPoint.LocationInCell pulse.Fall_90_10.EndPoint.LocationInCell], [pulse.Fall_90_10.EndPoint.Value pulse.Fall_90_10.EndPoint.Value], 'Color', clrRiseFall_10_90, 'LineStyle', '--', 'LineWidth', 0.5, 'Marker', 'v', 'MarkerFaceColor', clrRiseFall_10_90, 'MarkerSize', 3);
                    end
                end
            end

            grid on;

            % build legend entires
            legendHandlers = [legendHandlers, hRawBaselineCorrected];
            legendLabels = [legendLabels, "Raw Signal"];
            legendHandlers = [legendHandlers, hDenoisedBaselineCorrected];
            legendLabels = [legendLabels, "Denoised Signal"];
            if (cell.HasPulsesDetected)
                legendHandlers = [legendHandlers, hUpstrokeVelocity];
                legendLabels = [legendLabels, "Upstroke Velocity"];
                legendHandlers = [legendHandlers, hMaxUpstrokeVelocityPoint];
                legendLabels = [legendLabels, "Max Upstroke Velocity"];
                legendHandlers = [legendHandlers, hActivationPoint];
                legendLabels = [legendLabels, "Activation Point"];
                legendHandlers = [legendHandlers, hActivationTime];
                legendLabels = [legendLabels, "Activation Time"];
                legendHandlers = [legendHandlers, hAPDs];
                legendLabels = [legendLabels, strcat("APDs", " ", strAPDs)];
                if (Parameters.PulseDetection.SignalType == SignalType.Calcium)
                    hRise_10_90 = line(nan, nan, 'Color', clrRiseFall_10_90, 'LineWidth', 1, 'Marker', '^', 'MarkerFaceColor', clrRiseFall_10_90, 'MarkerSize', 3);
                    hFall_90_10 = line(nan, nan, 'Color', clrRiseFall_10_90, 'LineWidth', 1, 'Marker', 'v', 'MarkerFaceColor', clrRiseFall_10_90, 'MarkerSize', 3);
                    legendHandlers = [legendHandlers, hRise_10_90];
                    legendLabels = [legendLabels, "RiseTime 10% to 90%"];
                    legendHandlers = [legendHandlers, hFall_90_10];
                    legendLabels = [legendLabels, "FallTime 90% to 10%"];
                end
                legendHandlers = [legendHandlers, hPulseFrame];
                legendLabels = [legendLabels, "Pulses detected"];
            end
            legendHandlers = [legendHandlers, hStimuliStart];
            legendLabels = [legendLabels, "Stimuli start times"];
            legendHandlers = [legendHandlers, hZeroLine];
            legendLabels = [legendLabels, "Zero"];
            legendHandlers = [legendHandlers, hThresholdLine];
            legendLabels = [legendLabels, convertContainedStringsToChars(strcat("Threshold", " ", num2str(Parameters.PulseDetection.ThresholdPercentage), "%"))];
            
            % show legend
            legend(legendHandlers, legendLabels);
            
            % title
            title(cell.TitleFigurePulseAnalysis);
            
            Log.EndBlock(startCreateFigurePulseAnalysis, 4, strcat("Finished creating Visualization of Pulse Analysis for Cell_ID: ", num2str(cell.ID)));
        end        
        
    end
end

