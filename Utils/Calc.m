% CLASS DESCRIPTION 
% The class contains calculation routines uses through the framework
% NOTES:
%
% RELEASE VERSION: 0.6
%
% AUTHOR: Anton Shpak (a.shpak@victorchang.edu.au)
%
% DATE: February 2020

classdef Calc
    
    methods (Static)
        
        function [peaks] = PeaksPoints(inY, selRatio, threshRatio, extrema)

            %peakLoc = [];
            %peakMag = [];
            
            [peakLoc, peakMag] = Calc.Peaks(inY, selRatio, threshRatio, extrema);

            if (isempty(peakLoc) && isempty(peakMag))
                peaks = [];
                return;
            end
                
            peaks(length(peakLoc), 1) = Point;

            if (~isempty(peakLoc) && ~isempty(peakMag)) && (length(peakLoc) == length(peakMag))
                for i = 1  : length(peakLoc)
                    pair = Point(peakLoc(i), peakMag(i));
                    peaks(i) = pair;
                end
            end
        end

        function [peakLoc, peakMag] = Peaks(inY, selRatio, threshRatio, extrema)
            
            sel = (max(inY) - min(inY))/selRatio;  % selectivity, default: (max(inY) - min(inY))/4
            
            % A threshold value which peaks must be larger than to be maxima or smaller than to be minima.
            thresh = max(inY)/threshRatio;   % default max(inY)/2
            
            %extrema: 1 for maxima, -1 for minima
            
            includeEndpoints = true;
            interpolate = false;

            [peakLoc, peakMag] = peakfinder(inY, sel, thresh, extrema, includeEndpoints, interpolate);
        end
        
        
        function [rises, falls] = RisesAndFalls(signal, thresholdLevel)
            
            [intersectionLocations, ~] = Calc.SignalAndHorzLineIntersections(signal, thresholdLevel);
            
%             [xi, yi] = polyxpoly(x,th, x,referenceSignal'); % requires Mappning Toolbox
%             intersectionLocations = xi;

%             figure();
%             plot(x, th);
%             hold on;
%             plot(x, referenceSignal);
%             plot(P(1,:), P(2,:), 'ro');
%             %  plot(xi, yi, 'ko');
            
            rises = zeros(0,1);
            falls = zeros(0,1);
            
            if (length(intersectionLocations) > 0)
                for i = 1 : length(intersectionLocations)
                    
                    pt = intersectionLocations(i);
                    
                    if (rem(pt, 1) == 0) % if integer
                        if (pt > 1 && pt <= length(signal))
                            prevVal = signal(pt - 1);

                            if (prevVal < thresholdLevel)
                                falls = [falls pt];
                            else %if (prevVal >= 0)
                                rises = [rises pt];
                            end
                        else % if (pt == 1))
                            nextVal = signal(pt + 1);

                            if (nextVal > thresholdLevel)
                                rises = [rises pt];
                            else %if (nextVal <= 0)
                                falls = [falls pt];
                            end

                        end
                    else % if not integer
                       prevPt = floor(pt);
                       prevVal = signal(prevPt);
                       
                       if (prevVal > thresholdLevel)
                           falls = [falls pt];
                       else
                           rises = [rises pt];
                       end
                    end
                end
            end
            
%             xx1 = P(1,1);
%             xx2 = P(1,2);
%             dd = cumtrapz([xx1, xx2], a);            
        end
        
        function [intersectionLocations, intersectionValues] = SignalAndHorzLineIntersections(signal, lineY)

            signalLength = length(signal);
            indexes = 1 : signalLength;

            line = zeros(1, signalLength);
            line(1:signalLength) = lineY;

            % intersections detection
            P = Calc.Intersections(indexes, line, indexes, signal', 100);
            intersectionLocations = P(1, :);
            intersectionValues = P(2, :);
        end

        % intersections detection
        function P = Intersections(x1, y1, x2, y2, wndSize)
            % split the signal to smaller windows, because of preformance
            
            signalLength = length(x2);
            
            intNumberOfWindows = floor(signalLength/wndSize);
            signalPartLeft = signalLength - wndSize*intNumberOfWindows;
            
            endInd = 1;
            P = zeros(0, 1);
            for i = 1 : intNumberOfWindows+1
                
                startInd = endInd;
                
                if (i == intNumberOfWindows+1)
                    if (signalPartLeft > 0)
                        if (intNumberOfWindows == 0)
                            endInd = signalPartLeft;
                        else
                            endInd = startInd +  signalPartLeft;
                        end
                    else
                        break;
                    end
                else
                    endInd = i * wndSize;
                end
                
                tempP = InterX([x1(startInd : endInd); y1(startInd : endInd)], [x2(startInd : endInd); y2(startInd : endInd)]);
                
                P = [P tempP];
            end

        end
        
    end
end

