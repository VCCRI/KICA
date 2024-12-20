% CLASS DESCRIPTION 
%
% NOTES:
%
% RELEASE VERSION: 0.6
%
% AUTHOR: Anton Shpak (a.shpak@victorchang.edu.au)
%
% DATE: February 2020
classdef (Abstract) Stroke < Interval
    
    properties(Dependent)

        StartTime_ms;

    end

    methods
        % constructor
        function obj = Stroke(pulse, id, description, comments)
            
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
            obj@Interval(argsBase{:});       

        end
        
        
        
        % StartTime_ms
        function res = get.StartTime_ms(self)
            % perform correction by -1 as indexes in array start with 1
            res = (self.StartPoint.LocationInCell - 1) * Sampling.Period_ms;
        end
        
     
          
    end    
    
end

