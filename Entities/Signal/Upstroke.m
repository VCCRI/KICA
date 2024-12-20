% CLASS DESCRIPTION 
%
% NOTES:
%
% RELEASE VERSION: 0.6
%
% AUTHOR: Anton Shpak (a.shpak@victorchang.edu.au)
%
% DATE: February 2020
classdef Upstroke < Stroke
    
    properties(Dependent)

        % Upstroke
        PeakTime_ms;
        PeakValue;
        RiseTime_ms;

        % Upstroke Velocity
        MaxVelocity;
        MaxVelocityTime_ms;
        MaxVelocityValue;
        Velocity;

    end

    methods
        % constructor
        function obj = Upstroke(pulse, id, description, comments)
            
            if (nargin == 0) 
                argsBase = {};
            elseif (nargin == 2)
                argsBase{1} = pulse;   
                argsBase{2} = id;   
                argsBase{3} = "";
                argsBase{4} = "";
            elseif (nargin == 4)
                argsBase{1} = pulse;   
                argsBase{2} = id;   
                argsBase{3} = description;
                argsBase{4} = comments;
            else
                error('Wrong number of input arguments');
            end

            % Call base class constructor
            obj@Stroke(argsBase{:});       

        end
        
        
        
        
        % Upstroke
        function res = get.PeakTime_ms(self)
            % perform correction by -1 as indexes in array start with 1
            res = (self.EndPoint.LocationInCell - 1) * Sampling.Period_ms;
        end
        
        function res = get.PeakValue(self)
            res = self.EndPoint.Value;
        end

        function res = get.RiseTime_ms(self)
            res = (self.EndPoint.Location - self.StartPoint.Location)  * Sampling.Period_ms;
        end
        

        
        % Upstroke Velocity
        function res = get.MaxVelocity(self)
            % use MaxUpstrokeVelocityPoint to properly detect Upstroke velocity for signals with EAD
            [max_dFdt_val, max_dFdt_loc] = max(self.Pulse.Denoised_dFdt(1 : self.EndPoint.Location));
            res = PointInPulse(max_dFdt_loc, self.Pulse.ToLocationInCell(max_dFdt_loc), max_dFdt_val);
        end
        
        function res = get.MaxVelocityTime_ms(self)
            % perform correction by -1 as indexes in array start with 1
            res = (self.MaxVelocity.LocationInCell - 1) * Sampling.Period_ms;
        end
        
        function res = get.MaxVelocityValue(self)
            res = self.MaxVelocity.Value;
        end
        
        function res = get.Velocity(self)
            res = (self.EndPoint.Value - self.StartPoint.Value) / self.RiseTime_ms;     
        end
        
    end    
    
end

