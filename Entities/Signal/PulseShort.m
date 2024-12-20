% CLASS DESCRIPTION 
%
% NOTES:
%
% RELEASE VERSION: 0.6
%
% AUTHOR: Anton Shpak (a.shpak@victorchang.edu.au)
%
% DATE: February 2020
classdef PulseShort < BaseSignal
 
    properties

        Cell;
        
        % range
        Start = double.empty;
        End = double.empty;
        
        % denoised signal
        Denoised;

    end
    
    properties (Access = protected)
    
        minDenoised = PointInPulse();
        maxDenoised = PointInPulse();
    
        maximumExt = PointInPulse();
        minimumExt = PointInPulse();
    end
    
    
    properties(Dependent)
        
        CellID;
        
        StartTime_ms;
        EndTime_ms;
        
        MaxDenoised;
        MinDenoised;
    
        % Analytical
        IsWithinStimulationWindow;
    end    
    
    methods

        % Constructor
        function obj = PulseShort(startLocation, endLocation, cell, id, description, comments)
            
            % create base class constructor arguments
             if nargin == 0 % NEED THE EMPTY CONSTRUCTOR FOR ARRAY SUPPORT
                argsBase = {};
            elseif nargin == 3
                argsBase{1} = double.empty;
                argsBase{2} = "";
                argsBase{3} = "";
                argsBase{4} = cell.Times(startLocation : endLocation);
                argsBase{5} = cell.RawBaselineCorrected(startLocation : endLocation);
            elseif nargin == 6
                argsBase{1} = id;
                argsBase{2} = description;
                argsBase{3} = comments;
                argsBase{4} = cell.Times(startLocation : endLocation);
                argsBase{5} = cell.RawBaselineCorrected(startLocation : endLocation);
            else
                error('Wrong number of input arguments');
            end

            % Call base class constructor
            obj@BaseSignal(argsBase{:});       
         
            if (nargin == 0) % NEED THE EMPTY CONSTRUCTOR FOR ARRAY SUPPORT
                obj.Start = double.empty; 
                obj.End = double.empty;
            elseif (nargin == 3) || (nargin == 6)
                % init properties
                obj.Cell = cell;
                
                obj.Update(startLocation, endLocation);
                return;
            else
                error('Wrong number of input arguments')
            end
           
            obj.Init();
        end
        
        
        function Update(self, startLocation, endLocation)
            self.Start = startLocation;
            self.End = endLocation;
            
            self.Denoised = self.Cell.DenoisedBaselineCorrected(startLocation : endLocation);
            
            self.Init();
        end
        
        
        
        % Location convert
        % converts coordinate within the Pulse to coordinate within the Cell
        function res = ToLocationInCell(self, locationInPulse)
            res = locationInPulse + self.Start - 1;
        end
        
        % converts coordinate within the Cell to coordinate within the Pulse
        function res = ToLocationInPulse(self, locationInCell)
            res = locationInCell - self.Start + 1;
        end

        
        % Dependent Properties
        
        % CellID
        function res = get.CellID(self)
            res = double.empty;
            if (~isempty(self.Cell))
                res = self.Cell.ID;
            end
        end        
        
        % start and end time
        function res = get.StartTime_ms(self)
            % perform correction by -1 as indexes in array start with 1
            res = (self.Start - 1) * Sampling.Period_ms;
        end
        
        function res = get.EndTime_ms(self)
            % perform correction by -1 as indexes in array start with 1
            res = (self.End - 1) * Sampling.Period_ms;
        end
        
        % Min and Max Denoised
        function res = get.MaxDenoised(self)
            res = self.maxDenoised;
        end
            
        function res = get.MinDenoised(self)
            res = self.minDenoised;
        end

        
        %Analytical
        
        % detect if the pulse is within the stimulation window
        function res = get.IsWithinStimulationWindow(self)
             res = (self.Start < Stimulation.StimulationEnd) && (self.End > Stimulation.StimulationStart);
        end
        
    end
    

    methods (Access = protected)
        
        % performs initial calculations
        function Init(self)
            Init@BaseSignal(self);
            
            self.maximumExt = PointInPulse(self.maximum.Location, self.ToLocationInCell(self.maximum.Location), self.maximum.Value);
            self.minimumExt = PointInPulse(self.minimum.Location, self.ToLocationInCell(self.minimum.Location), self.minimum.Value);
            
            [maxDenoisedValue, maxDenoisedLocation] = max(self.Denoised);
            self.maxDenoised = PointInPulse(maxDenoisedLocation, self.ToLocationInCell(maxDenoisedLocation), maxDenoisedValue);
            
            [minDenoisedValue, minDenoisedLocation] = min(self.Denoised);
            self.minDenoised = PointInPulse(minDenoisedLocation, self.ToLocationInCell(minDenoisedLocation), minDenoisedValue);
        end
        
        
        % override from BaseSignal
        function res = getMax(self)
            res = self.maximumExt;
        end

        % override from BaseSignal
        function res = getMin(self)
            res = self.minimumExt;
        end
        
    end    
    
end

