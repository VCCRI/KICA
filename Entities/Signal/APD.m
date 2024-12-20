% CLASS DESCRIPTION 
%
% NOTES:
%
% RELEASE VERSION: 0.6
%
% AUTHOR: Anton Shpak (a.shpak@victorchang.edu.au)
%
% DATE: February 2020
classdef APD < Interval

    properties (GetAccess = public, SetAccess = private)
        Percentage = double.empty;
    end
    

    methods
        % constructor
        function obj = APD(pulse, percentage, description, comments)
            
            if (nargin == 0) 
                argsBase = {};
            elseif (nargin == 2)
                argsBase{1} = pulse;   
                argsBase{2} = percentage;   
                argsBase{3} = "";
                argsBase{4} = "";
            elseif (nargin == 4)
                argsBase{1} = pulse;   
                argsBase{2} = percentage;   
                argsBase{3} = description;
                argsBase{4} = comments;
            else
                error('Wrong number of input arguments');
            end

            % Call base class constructor
            obj@Interval(argsBase{:});       

            if (nargin == 0)
                obj.Percentage = double.empty;
            elseif (nargin == 2) || (nargin == 4)
                obj.Percentage = percentage;
            end
        end
        
        
    end
    
    
end

