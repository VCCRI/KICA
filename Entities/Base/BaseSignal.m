classdef (Abstract) BaseSignal < BaseEntity
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
        Times;  % times
        Raw;    % raw fluorescence

        Min;
        Max;
    end
    
    properties (Access = protected)
        minimum = Point(double.empty, double.empty);
        maximum = Point(double.empty, double.empty);
    end

    properties (Dependent)
        Amplitude;
        Duration;       % [samples]
        Duration_ms;    % [ms]
    end
    
    methods
        
        % Constructor
        function obj = BaseSignal(id, description, comments, times, rawValues)
%             if (length(times) ~= length(rawValues))
%                 throw MException('Sizes of Times and RawMagnitudes do not match');
%             end
            
            % create base class constructor arguments
            if nargin == 0 % NEED THE EMPTY CONSTRUCTOR FOR ARRAY SUPPORT
                argsBase{1} = double.empty;
                argsBase{2} = "";
                argsBase{3} = "";
            elseif nargin == 5
                argsBase{1} = id;
                argsBase{2} = description;
                argsBase{3} = comments;
            else
                error('Wrong number of input arguments');
            end

            % Call base class constructor
            obj@BaseEntity(argsBase{:});       


            if (nargin == 0) % NEED THE EMPTY CONSTRUCTOR FOR ARRAY SUPPORT
                obj.Times = double.empty;
                obj.Raw = double.empty;
            elseif (nargin == 5)
                obj.Times = times;
                obj.Raw = rawValues;
            end
            
            obj.Init();
        end
        
        % Properties with (GetAccess = public, SetAccess = protected)
        
        % MaxLocation
        function res = get.Max(self)
            % to have a possibility to override
            res = self.getMax();
        end
        
        % MinLocation
        function res = get.Min(self)
            % to have a possibility to override
            res = self.getMin();
        end
        
        
        % Dependent properties
        
        % Amplitude
        function res = get.Amplitude(self)
            res = self.Max.Value - self.Min.Value;
        end
        
        % Duration
        function res = get.Duration(self)
            res = length(self.Raw) - 1;
        end
        
        % Duration_ms
        function res = get.Duration_ms(self)
            res = self.Times(end) - self.Times(1);
        end
        
    end
    
    
   
    methods (Access = protected)
        
        % performs initial calculations
        function Init(self)
            [self.maximum.Value, self.maximum.Location] = max(self.Raw);
            [self.minimum.Value, self.minimum.Location] = min(self.Raw);
        end
        
    end    
    
    methods (Access = protected)
        % protected in order to have possibility to override in a child class
        function res = getMin(self)
            res = self.minimum;
        end

        % protected in order to have possibility to override in a child class
        function res = getMax(self)
            res = self.maximum;
        end

    end
    
end

