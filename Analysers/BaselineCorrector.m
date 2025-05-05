classdef BaselineCorrector
% CLASS DESCRIPTION
% Provides static methods for baseline correction of signals.
%
% NOTES:
% Uses msbackadj for core baseline estimation. Aims for robust parameter
% estimation for single-pass correction. Handles msbackadj output correctly.
%
% RELEASE VERSION: 0.8
%
% AUTHOR: Anton Shpak (a.shpak@victorchang.edu.au)
%         Satya Arjunan (s.arjunan@victorchang.edu.au)
%
% DATE: May 2025 % Updated Date

    methods (Static)
        function [outValues, baseline] = CorrectBaseline(inLocations, inValues, regressionMethod)
            % Corrects the baseline of input signal values.
            %
            % INPUTS:
            %   inLocations: Vector of sample locations (e.g., time or m/z).
            %   inValues: Vector of corresponding signal values.
            %   regressionMethod: Method for msbackadj ('spline', 'polynomial', 'linear', 'pchip').
            %                     'spline' or 'pchip' are generally recommended for flexibility.
            %                     If 'polynomial', it should be passed as {'polynomial', order}, e.g. {'polynomial', 2}.
            %
            % OUTPUTS:
            %   outValues: Baseline-corrected signal values.
            %   baseline: Estimated baseline values.

            % --- Parameters ---
            % Peak finding parameters (for estimating feature width)
            selRatio = 4;           % Parameter for Calc.Peaks (selectivity)
            threshRatio = 6;        % Parameter for Calc.Peaks (threshold)
            extrema = 1;            % Parameter for Calc.Peaks (1 for peaks, -1 for valleys)
            minPeaksForDistance = 3; % Minimum number of peaks needed to calculate median distance

            % msbackadj window/step size calculation parameters
            % stepSize: Determines how often the baseline is estimated.
            % windowSize: Determines the local data range used for each estimation.
            % windowSize should generally be significantly larger than stepSize for smoothing.

            % stepSizeFactor:
            %   Controls the resolution of the baseline by determining how often the window is moved and the baseline calculation
            %   is updated. A smaller value increases the resolution of the baseline, allowing it to change slope more rapidly.
            % windowSizeFactor:
            %   Controls the locality of the baseline. If the baseline is not smooth enough, increase the factor.
            %   If the baseline seems too smooth and misses some curvature, decrease it.
            % quantileValue:
            %   Controls the vertical position of the baseline, lower value pulls baseline down, higher value pushes it up.

            stepSizeFactor = 0.25;   % Factor of peakDistance to determine stepSize
            windowSizeFactor = 4.5; % Factor of stepSize to determine windowSize (WindowSize = peakDistance * stepSizeFactor * windowSizeFactor)
            quantileValue = 0.025;  % Lower quantile values are more conservative (less likely to include signal)

            defaultPeakDistanceFactor = 0.05; % Factor of signal length if peak finding fails (e.g., 1/20th)
                                    % Example: windowSize = peakDistance * 0.5 * 4.0 = 2 * peakDistance
            minStepSize = 10;       % Minimum allowed step size
            minWindowSize = 30;     % Minimum allowed window size
            maxNumWindows = 1000;   % Maximum number of estimation windows (limits stepSize if too small)

            smoothMethod = 'none';  % Smoothing within msbackadj (usually 'none' is fine)
            showPlotInternal = 0;   % Set to 1 for msbackadj's internal plot (debugging)
            % ------------------

            if isempty(inValues) || length(inValues) < 2
                Log.Message(2, "Baseline correction: Input data is empty or too short.");
                outValues = inValues;
                baseline = zeros(size(inValues));
                return;
            end

            if ~isvector(inLocations) || ~isvector(inValues) || length(inLocations) ~= length(inValues)
                 error('Inputs inLocations and inValues must be vectors of the same length.');
            end
            % Ensure inputs are double-precision column vectors
            inValues = double(inValues(:));
            inLocations = double(inLocations(:));

            if iscell(regressionMethod) % Handle polynomial case for logging
                regMethodStr = regressionMethod{1};
                if numel(regressionMethod)>1
                     regMethodStr = [regMethodStr, ' order ' num2str(regressionMethod{2})];
                end
            else
                regMethodStr = regressionMethod;
            end
            Log.Message(3, sprintf('Baseline correction started. Signal length: %d. Method: %s.', length(inValues), regMethodStr));


            % 1. Estimate characteristic peak distance for setting window/step sizes
            % Use initially detrended data for potentially clearer peaks
            try
                detrendedValues = detrend(inValues, 1); % Linear detrend
                [peakLocationsIdx, ~] = Calc.Peaks(detrendedValues, selRatio, threshRatio, extrema);
            catch ME_PeakFind
                 Log.ErrorMessage(2, ['Baseline correction: Error during initial peak finding using Calc.Peaks. ',...
                                     'Proceeding with default distance estimate. Error: ', ME_PeakFind.message]);
                 peakLocationsIdx = [];
            end

            peakDistance = NaN;
            if length(peakLocationsIdx) >= minPeaksForDistance
                % Calculate median difference for robustness
                peakDistances = diff(sort(peakLocationsIdx));
                if ~isempty(peakDistances)
                     peakDistance = median(peakDistances(peakDistances > 0)); % Use median and ensure positive
                end
                 Log.Message(3, sprintf('Baseline correction: Found %d peaks. Median peak distance: %.2f', length(peakLocationsIdx), peakDistance));
            end

            % Handle cases where peak distance calculation failed
            if isnan(peakDistance) || peakDistance <= 0
                defaultDist = ceil(length(inValues) * defaultPeakDistanceFactor);
                Log.Message(3, sprintf('Baseline correction: Could not estimate peak distance reliably (found %d peaks). Using default based on signal length: %d', length(peakLocationsIdx), defaultDist));
                peakDistance = defaultDist;
                if peakDistance < minStepSize % Ensure default isn't too small based on step size factor
                    peakDistance = minStepSize / stepSizeFactor; % Estimate required peak distance for min step size
                    if peakDistance < 1; peakDistance = 1; end % Avoid zero or negative
                     Log.Message(3, sprintf('Baseline correction: Adjusted default peak distance to %d to ensure minimum step size.', ceil(peakDistance)));
                end
                 peakDistance = max(1, peakDistance); % Ensure peak distance is at least 1
            end

            % 2. Calculate StepSize and WindowSize based on peakDistance
            stepSize = max(minStepSize, round(peakDistance * stepSizeFactor));
            windowSize = max(minWindowSize, round(stepSize * windowSizeFactor));

            % Ensure windowSize is larger than stepSize
            if windowSize <= stepSize
                originalWindowSize = windowSize;
                windowSize = max(minWindowSize, round(stepSize * 1.5)); % Ensure window is at least somewhat larger
                Log.Message(3, sprintf('Baseline correction: Calculated windowSize (%d) was <= stepSize (%d). Adjusted windowSize to %d.', originalWindowSize, stepSize, windowSize));
            end

            % Limit stepSize if it implies too many windows (performance)
            numWindowsEstimate = length(inValues) / stepSize;
            if numWindowsEstimate > maxNumWindows
                originalStepSize = stepSize;
                stepSize = ceil(length(inValues) / maxNumWindows);
                stepSize = max(stepSize, 1); % Ensure step size is at least 1
                % Recalculate windowSize based on the adjusted stepSize
                windowSize = max(minWindowSize, round(stepSize * windowSizeFactor));
                 % Ensure windowSize is still larger than adjusted stepSize
                if windowSize <= stepSize
                    windowSize = max(minWindowSize, round(stepSize * 1.5));
                end
                Log.Message(3, sprintf('Baseline correction: Estimated windows (%.1f) exceeded max (%d). Adjusted stepSize from %d to %d, windowSize to %d.', numWindowsEstimate, maxNumWindows, originalStepSize, stepSize, windowSize));
            end

            % Clamp window size to not exceed signal length (msbackadj requirement)
             if windowSize > length(inValues)
                 Log.Message(3, sprintf('Baseline correction: Calculated windowSize (%d) exceeds signal length (%d). Clamping windowSize to %d.', windowSize, length(inValues), length(inValues)));
                 windowSize = length(inValues);
                 % Ensure step size is smaller than clamped window size
                 if stepSize >= windowSize && windowSize > 1
                     stepSize = max(1, floor(windowSize / 1.5)); % Keep step < window
                     Log.Message(3, sprintf('Baseline correction: Clamped windowSize required adjusting stepSize to %d.', stepSize));
                 elseif windowSize <= 1 % Handle edge case of signal length 1
                     stepSize = 1;
                 end
             end


            Log.Message(3, sprintf('Baseline correction: Using stepSize=%d, windowSize=%d, quantile=%.3f', stepSize, windowSize, quantileValue));

            % 3. Perform baseline correction using msbackadj (single pass)
            outValues = []; % Initialize to ensure scope if try fails before assignment
            baseline = []; % Initialize to ensure scope if try fails before assignment
            try
                % msbackadj returns only the baseline-corrected signal.
                correctedSignal = msbackadj(inLocations, inValues, ...
                                'RegressionMethod', regressionMethod,...
                                'StepSize', stepSize,...
                                'WindowSize', windowSize,...
                                'SmoothMethod', smoothMethod,...
                                'QuantileValue', quantileValue,...
                                'ShowPlot', showPlotInternal); % Use internal plot flag

                % Check if the output size matches input size (essential)
                if ~isequal(size(correctedSignal), size(inValues))
                     % This might happen if msbackadj fails internally in a way not caught
                     % or if inputs were somehow mismatched despite checks.
                     error('msbackadj returned a signal of unexpected size (%d x %d) vs input (%d x %d)', ...
                           size(correctedSignal,1), size(correctedSignal,2), size(inValues,1), size(inValues,2));
                end

                % Assign the corrected signal to outValues
                outValues = correctedSignal(:); % Ensure column vector

                % Calculate the baseline by subtracting the corrected signal from the original
                baseline = inValues(:) - outValues(:); % Ensure column vectors for subtraction

                Log.Message(3, "Baseline correction: msbackadj executed successfully.");

            catch ME_msbackadj
                Log.ErrorMessage(1, ['Baseline correction FAILED using msbackadj. ID: ', ME_msbackadj.identifier, ' Message: ', ME_msbackadj.message]);
                % Return original data if correction fails
                outValues = inValues(:); % Ensure column vector
                baseline = zeros(size(inValues)); % Return zero baseline on failure
            end

            % Final check on output sizes (should be redundant now but safe)
             if ~isequal(size(outValues), size(inValues)) || ~isequal(size(baseline), size(inValues))
                 Log.Message(1, 'Baseline correction: Final output size mismatch after processing. Reverting to original.');
                 outValues = inValues(:);
                 baseline = zeros(size(inValues));
            end

             Log.Message(3, "Baseline correction: Completed.");
        end
    end

end % End of classdef

