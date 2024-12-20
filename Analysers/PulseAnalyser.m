classdef PulseAnalyser < handle
% CLASS DESCRIPTION 
%
% NOTES:
%
% RELEASE VERSION: 0.6
%
% AUTHOR: Anton Shpak (a.shpak@victorchang.edu.au)
%
% DATE: February 2020
    
    
    properties (GetAccess = public, SetAccess = protected)
        
        Pulse = Pulse();
        
    end
    
    properties (Access = private)
        peaks_denoised = Point.empty;
        peaks_denoised_dFdt = Point.empty;
        
        minima_denoised = Point.empty; % trough
        minima_denoised_dFdt = Point.empty;
        
        rises_dFdt = PointInPulse.empty;
        falls_dFdt = PointInPulse.empty;

    end
    
    methods
        
        % constructor
        function obj = PulseAnalyser(pulse)
            obj.Pulse = pulse;
        end
                
    
        function StartAnalysis(self)
            
            % 1 - Calculate Peaks 
            self.CalculatePeaks();
            
            % 2 - Calculate SubPulses, which include Upstroke and EADs if any
            self.FindSubPulses();
            
            % 3 - Calculate Point for Activation Time (time of 50% of UpstrokePeakPoint)
            self.CalculateActivationPoint();
            
            % 4 - Calculate APDs (% of UpstrokePeakPoint)
            self.CalculateAPDs();
            
            % 5 - Calculate ratio APD30 / APD90
            self.CalculateAPD_30_90_Ratio();
            
            % 6 - Calculate intervals Rise 10% to 90% of Upstroke and Fall 90% to 10% of UpstrokePeakPoint (for calcium)
            self.CalculateRiseFall_10_90();
            
            % 7 - calculate if Pulse's start is within given tolerance time of stimulus
            self.CalculateIfPulseStartsOnStimulus();
        end
        
        
    end    
    
    
    
    methods (Access = private)
        
        function CalculatePeaks(self)

            if (isempty(self.Pulse.Denoised))
                return;
            end
            
            % 1 - Find Peaks for the Denoised
            selRatio = 50;      % <--- PARAM
            threshRatio = 2;    % <--- PARAM
            extrema = 1;        % <--- PARAM
            
            self.peaks_denoised = Calc.PeaksPoints(self.Pulse.Denoised, selRatio, threshRatio, extrema);
            
            % 2 - Find Minima for the Denoised
            selRatio_minima = 50;      % <--- PARAM
            threshRatio_minima = 2;    % <--- PARAM
            extrema_minima = -1;       % <--- PARAM
            
            self.minima_denoised = Calc.PeaksPoints(self.Pulse.Denoised, selRatio_minima, threshRatio_minima, extrema_minima);
            
            % 3 - Find Peaks for the Denoised_dFdt
            selRatio_dFdt = 50;         % <--- PARAM
            threshRatio_dFdt = 20;      % <--- PARAM
            extrema_dFdt = 1;           % <--- PARAM
            
            self.peaks_denoised_dFdt = Calc.PeaksPoints(self.Pulse.Denoised_dFdt, selRatio_dFdt, threshRatio_dFdt, extrema_dFdt);
                       
            % 4 - Find Minima for the Denoised_dFdt
            selRatio_minima_dFdt = 1000;       % <--- PARAM
            threshRatio_minima_dFdt = 20;      % <--- PARAM
            extrema_minima_dFdt = -1;          % <--- PARAM
            
            self.minima_denoised_dFdt = Calc.PeaksPoints(self.Pulse.Denoised_dFdt, selRatio_minima_dFdt, threshRatio_minima_dFdt, extrema_minima_dFdt);
            
            % 5 - Find Rises and Falls for the Denoised_dFdt inntersection with zero
            [rises_dFdt_, falls_dFdt_] = Calc.RisesAndFalls(self.Pulse.Denoised_dFdt, 0);

            if (~isempty(rises_dFdt_))
                self.rises_dFdt(length(rises_dFdt_), 1) = PointInPulse();
                for i = 1 : length(rises_dFdt_)
                    self.rises_dFdt(i) = PointInPulse(rises_dFdt_(i), self.Pulse.ToLocationInCell(rises_dFdt_(i)), 0);
                end
            end
            
            if (~isempty(falls_dFdt_))
                self.falls_dFdt(length(falls_dFdt_), 1) = PointInPulse();
                for i = 1 : length(falls_dFdt_)
                    self.falls_dFdt(i) = PointInPulse(falls_dFdt_(i), self.Pulse.ToLocationInCell(falls_dFdt_(i)), 0);
                end
            end
            
        end
        
        % Calculate SubPulses, which include Upstroke and EADs if any
        function FindSubPulses(self)
            
            % 1 - Find Upstrokes
            upstrokes = self.CalculateUpstrokes();
            
            % 2 - Find Downstrokes
            downstrokes = self.CalculateDownstrokes(upstrokes);
            
            % 3 - Build UpDowns
            
            if (length(upstrokes) == length(downstrokes) && ~isempty(upstrokes) && ~isempty(downstrokes))
                updowns(length(upstrokes), 1) = UpDown();
                
                for i = 1 : length(upstrokes)
                    updowns(i) = UpDown(self.Pulse, upstrokes(i), downstrokes(i));
                end
                
                % 4 - Calculate SubPulses
                self.Pulse.SetValues_SubPulses(self.CalculateSubPulses(updowns));
                
            end
            
        end        
        
        function upstrokes = CalculateUpstrokes(self)
            
            upstrokes = Upstroke.empty;
            
            if (isempty(self.peaks_denoised_dFdt))
                return;
            end

            
            counter = 1;
            upstrokeEndSearch_ItervalStart = double.empty;
            for i = 1 : length(self.peaks_denoised_dFdt)
                % detect UpstrokeEnd
                if (isempty(upstrokeEndSearch_ItervalStart)) 
                    % i.e. if it is the first upstroke or an upstroke was
                    % found for previous peak_dFdt
                    upstrokeEndSearch_ItervalStart = self.peaks_denoised_dFdt(i).Location;
                end
                
                if (i == length(self.peaks_denoised_dFdt))
                    upstrokeEndSearch_IntervalEnd = self.Pulse.ToLocationInPulse(self.Pulse.End);
                else
                    upstrokeEndSearch_IntervalEnd = self.peaks_denoised_dFdt(i+1).Location;
                end
                
                peaksLocations = [self.peaks_denoised.Location];
                peakLocationsWithinInterval = peaksLocations((upstrokeEndSearch_ItervalStart <= peaksLocations) & (peaksLocations < upstrokeEndSearch_IntervalEnd));
                
                if (isempty(peakLocationsWithinInterval))
                    
                    % reset if the interval doesn't contain a peak but contains a deep fall
                    if (isempty(self.minima_denoised))
                        minima_denoised_locations = 0;
                    else
                        minima_denoised_locations = [self.minima_denoised.Location];
                    end
                    minima_denoised_locationsWithinInterval = minima_denoised_locations((upstrokeEndSearch_ItervalStart <= minima_denoised_locations) & (minima_denoised_locations < upstrokeEndSearch_IntervalEnd));
                    if (~isempty(minima_denoised_locationsWithinInterval))
                        upstrokeEndSearch_ItervalStart = double.empty;
                    end
                    
                    continue;
                end
                
                % UpstrokeEnd found
                upstrokeEnd = Point(peakLocationsWithinInterval(1), self.Pulse.Denoised(peakLocationsWithinInterval(1)));
                
                
                % detect UpstrokeStart
                if (isempty(upstrokes))
                    upstrokeStartSearch_ItervalStart = self.Pulse.ToLocationInPulse(self.Pulse.Start);
                else
                    upstrokeStartSearch_ItervalStart = (upstrokes(end).EndPoint.Location);
                end
                
                rises_dFdt_Locations = [self.rises_dFdt.Location];
                rises_dFdt_LocationsWithinInterval = rises_dFdt_Locations((rises_dFdt_Locations >= upstrokeStartSearch_ItervalStart) & (rises_dFdt_Locations < upstrokeEndSearch_ItervalStart));
                
                minima_dFdt_Locations = [self.minima_denoised_dFdt.Location];
                minima_dFdt_LocationsWithinInterval = minima_dFdt_Locations((minima_dFdt_Locations >= upstrokeStartSearch_ItervalStart) & (minima_dFdt_Locations < upstrokeEndSearch_ItervalStart));
                
                upPoints = union(rises_dFdt_LocationsWithinInterval, minima_dFdt_LocationsWithinInterval);
                
                if (isempty(rises_dFdt_LocationsWithinInterval))
                    upstrokeStartLocation = upstrokeStartSearch_ItervalStart;
                else
                    % start of the latest rising sub-interval within interval
                    upstrokeStartLocation = upPoints(end);
                end
                upstrokeStartLocation = floor(upstrokeStartLocation); % floor !!!
                
                % UpstrokeStart found
                upstrokeStart = Point(upstrokeStartLocation, self.Pulse.Denoised(upstrokeStartLocation)); 
                
                % create Upstroke and add it into array
                upstrokes(counter) = Upstroke(self.Pulse, counter, "", "");
                upstrokes(counter).SetValues(upstrokeStart.Location, upstrokeStart.Value, false, upstrokeEnd.Location, upstrokeEnd.Value, false);
                
                % reset, i.e. mark that upstroke was found for current peak_dFdt
                upstrokeEndSearch_ItervalStart = double.empty;
                
                % increment counter as array index
                counter = counter + 1;
            end
            
        end        
        
        function downstrokes = CalculateDownstrokes(self, upstrokes)
            
            downstrokes = Downstroke.empty;
            
            if (isempty(upstrokes))
                return;
            end
            
            downstrokes(length(upstrokes), 1) = Downstroke();
            for i = 1 : length(upstrokes)
                upstroke = upstrokes(i);
                
                downstrokeStartPoint = upstroke.EndPoint;
                
                rises_dFdt_Locations = [self.rises_dFdt.Location];
                if (i <= (length(upstrokes) - 1))
                    % start of next upstroke if any
                    intervalEnd = upstrokes(i+1).StartPoint.Location;
                else
                    intervalEnd = self.Pulse.ToLocationInPulse(self.Pulse.End);
                end
                rises_dFdt_LocationsWithinInterval = rises_dFdt_Locations((rises_dFdt_Locations > upstroke.EndPoint.Location) & (rises_dFdt_Locations <= intervalEnd));
                
                if (isempty(rises_dFdt_LocationsWithinInterval))
                    downstrokeEndLocation = intervalEnd; % TODO: is it correct?
                else
                    % start of the last rising sub-interval within interval
                    downstrokeEndLocation = rises_dFdt_LocationsWithinInterval(1);
                end
                downstrokeEndLocation = floor(downstrokeEndLocation); % floor !!!
                
                downstrokes(i) = Downstroke(self.Pulse, i);
                downstrokes(i).SetValues(downstrokeStartPoint.Location, downstrokeStartPoint.Value, false,...
                                         downstrokeEndLocation, self.Pulse.Denoised(downstrokeEndLocation), false);

            end
            
            %self.Pulse.Downstrokes = self.downstrokes;
        end
        
        function subPulses = CalculateSubPulses(self, updowns)
            
            subPulses = SubPulse.empty;
            
            if (isempty(updowns))
                return;
            end
            
            countUpDownsInSubPulse = 1;
            countSubPulses = 1;
            for i = 1 : length(updowns)
                updown = updowns(i);
                
                if (i == 1)
                    updownsTmp = UpDown.empty;
                else
                    % TODO: only add UpDown if it is first or if its Peak > Peak_of_previous_UpDown
                    if (updown.StartPoint.Location ~= lastConsecuitiveLocation)
                        % create sub pulse, add previously filled array of updowns there
                        subPulses(countSubPulses) = SubPulse(self.Pulse, updownsTmp);
                       
                        % create new updowns array
                        updownsTmp = UpDown.empty;
                        countSubPulses = countSubPulses + 1;
                    end
                end
                
                % add current updown to the updowns array
                updownsTmp(countUpDownsInSubPulse) = updown;
                lastConsecuitiveLocation = updown.EndPoint.Location;
                countUpDownsInSubPulse = countUpDownsInSubPulse + 1;
                
                if (i == length(updowns))
                    % create sub pulse, add filled array of updowns there
                    subPulses(countSubPulses) = SubPulse(self.Pulse, updownsTmp);
                end                
            end
            
        end
        
        
        function CalculateActivationPoint(self)
            
            if (isempty(self.Pulse.UpstrokePeakPoint))
                return;
            end
            
            % 1. calc value at 50% of UpstrokePeak
            activationPointValue = self.Pulse.UpstrokePeakPoint.Value/2;
            
            % 2. find intersection of 50% line with the rising edge
            [activationPointLocation, ~] = self.FindLocationOnPulseEdge(activationPointValue, true, false);
            
            self.Pulse.SetValues_ActivationPoint(activationPointLocation, activationPointValue);
            
        end
        
        function CalculateAPDs(self)
            
            if (~isempty(self.Pulse.APDs))
                for i = 1 : length(self.Pulse.APDs)
                    self.CalculateAPD(self.Pulse.APDs(i));
                end
            end
    
        end
        
        function CalculateAPD_30_90_Ratio(self)
            
            apds = self.Pulse.APDs;

            idx = arrayfun(@(x)eq(x.Percentage, 30), apds);
            apds30 = apds(idx);
            if (~isempty(apds30))
                apd30 = apds30(1);
            else
                apd30 = APD(self.Pulse, 30, "", "");
                self.CalculateAPD(apd30);
            end

            idx = arrayfun(@(x)eq(x.Percentage, 90), apds);
            apds90 = apds(idx);
            if (~isempty(apds90))
                apd90 = apds90(1);
            else
                apd90 = APD(self.Pulse, 90, "", "");
                self.CalculateAPD(apd90);
            end
            
            self.Pulse.SetValue_APD_30_90_Ratio(apd30.Duration/apd90.Duration);

        end
        
        function CalculateAPD(self, apd)
            
            if (apd.Percentage >= 100) || (apd.Percentage <= 0) || (isempty(self.Pulse.ActivationPoint))
                return;
            end
            
            % start location is the same for all APDs, equals ActivationPoint.Location
            apdStartLocation = self.Pulse.ActivationPoint.Location;
            isStartLocationApproximated = false;

            % 1. calc APD level value
            apdValue = self.Pulse.UpstrokePeakPoint.Value * (1 - apd.Percentage/100);

            % 2. find location at the falling edge at this level
            [apdEndLocation, isEndPointApproximated] = self.FindLocationOnPulseEdge(apdValue, false, false);

            % 3. set values for the interval
            apd.SetValues(apdStartLocation, apdValue, isStartLocationApproximated, apdEndLocation, apdValue, isEndPointApproximated);

        end
        
        function CalculateRiseFall_10_90(self)
            if (Parameters.PulseDetection.SignalType == SignalType.Calcium)
                
                if (isempty(self.Pulse.UpstrokePeakPoint))
                    return;
                end
                
                valueAt10Percent = self.Pulse.UpstrokePeakPoint.Value * 0.1;
                valueAt90Percent = self.Pulse.UpstrokePeakPoint.Value * 0.9;
                
                [locationOn_RisingEdge_10, isLocationOn_RisingEdge_10_Approximated] = self.FindLocationOnPulseEdge(valueAt10Percent, true, false);
                [locationOn_RisingEdge_90, isLocationOn_RisingEdge_90_Approximated] = self.FindLocationOnPulseEdge(valueAt90Percent, true, false);
                
                [locationOn_FallingEdge_90, isLocationOn_FallingEdge_90_Approximated] = self.FindLocationOnPulseEdge(valueAt90Percent, false, true);
                [locationOn_FallingEdge_10, isLocationOn_FallingEdge_10_Approximated] = self.FindLocationOnPulseEdge(valueAt10Percent, false, false);
                
                
                self.Pulse.Rise_10_90.SetValues(locationOn_RisingEdge_10, valueAt10Percent, isLocationOn_RisingEdge_10_Approximated,...
                                                locationOn_RisingEdge_90, valueAt90Percent, isLocationOn_RisingEdge_90_Approximated);
                                                  
                self.Pulse.Fall_90_10.SetValues(locationOn_FallingEdge_90, valueAt90Percent, isLocationOn_FallingEdge_90_Approximated,...
                                                locationOn_FallingEdge_10, valueAt10Percent, isLocationOn_FallingEdge_10_Approximated);
                
            end
        end
        
        function CalculateIfPulseStartsOnStimulus(self)
            
            stimulusNumber = -1;
            
            switch Parameters.PulseAnalysis.PulseStartPointType
                case PulseStartPointType.UpstrokeStart
                    controlPointInPulse = self.Pulse.Upstroke.StartPoint;
                case PulseStartPointType.UpstrokeEnd
                    controlPointInPulse = self.Pulse.Upstroke.EndPoint;
                case PulseStartPointType.ActivationPoint
                    controlPointInPulse = self.Pulse.ActivationPoint;
                otherwise
                    controlPointInPulse = self.Pulse.ActivationPoint;
            end
            
            if (~isempty(controlPointInPulse))
                
                % perform correction by -1 as indexes start with 1
                controlPointInPulseTime_ms = (controlPointInPulse.LocationInCell - 1) * Sampling.Period_ms;
                
                intervalStart = controlPointInPulseTime_ms - Parameters.PulseAnalysis.PulseStartOnStimulusDetectionDelta_ms;
                intervalEnd = controlPointInPulseTime_ms + Parameters.PulseAnalysis.PulseStartOnStimulusDetectionDelta_ms;
                
                for i = 0 : Stimulation.StimuliNumber-1
                    stimulusTime = Stimulation.StimulationStart_ms + (Stimulation.StimuliPeriod_ms * i);
                    if ((intervalStart <= stimulusTime) && (stimulusTime <= intervalEnd))
                        stimulusNumber = i + 1;
                        break;
                    end
                end
            end
            
            self.Pulse.SetValue_PulseStartOnStimulusNumber(stimulusNumber);
        end        

        function [locationOnEdge, isLocationOnEdgeApproximated] = FindLocationOnPulseEdge(self, valueAtLocation, isRisingEdge, isLeftMost)
            
            % default (i.e. approximate) the point on falling edge to a point at end
            if (isRisingEdge)
                locationOnEdge = self.Pulse.ToLocationInPulse(self.Pulse.Start);
            else
                locationOnEdge = self.Pulse.ToLocationInPulse(self.Pulse.End);
            end
            isLocationOnEdgeApproximated = true;
            
            [rises, falls] = Calc.RisesAndFalls(self.Pulse.Denoised, valueAtLocation);

            if (isRisingEdge) && (~isempty(rises)) || ((~isRisingEdge) && (~isempty(falls)))
                
                isLocationFound = false;
                if (isRisingEdge)
                    rises = rises(rises <= self.Pulse.UpstrokePeakPoint.Location);
                    if (~isempty(rises))
                        if (isLeftMost)
                            [location, ~] = min(rises);     % the left-most
                        else
                            [location, ~] = max(rises);     % the right-most
                        end
                        isLocationFound = true;
                    end
                else
                    falls = falls(falls >= self.Pulse.UpstrokePeakPoint.Location);
                    if (~isempty(falls))
                        if (isLeftMost)
                            [location, ~] = min(falls);     % the left-most
                        else
                            [location, ~] = max(falls);     % the right-most
                        end
                        isLocationFound = true;
                    end
                end

                if (isLocationFound == true)
                    locationOnEdge = location;
                    isLocationOnEdgeApproximated = false;
                end
            end
        end
        
        
        
        
        function CalculateEAD(self)
            % TODO
        end
        
    end    

end

