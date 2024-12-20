% CLASS DESCRIPTION 
%
% NOTES:
%
% RELEASE VERSION: 0.6
%
% AUTHOR: Anton Shpak (a.shpak@victorchang.edu.au)
%
% DATE: February 2020
classdef Downstroke < Stroke

    methods
        % constructor
        function obj = Downstroke(pulse, id)
            
            if (nargin == 0) 
                argsBase = {};
            elseif (nargin == 2)
                argsBase{1} = pulse;   
                argsBase{2} = id;   
                argsBase{3} = "";
                argsBase{4} = "";
            else
                error('Wrong number of input arguments');
            end

            % Call base class constructor
            obj@Stroke(argsBase{:});       

        end
        
        
    end    
    
end

