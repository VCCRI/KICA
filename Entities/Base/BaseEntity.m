classdef (Abstract) BaseEntity < matlab.mixin.Copyable % handle
% CLASS DESCRIPTION:
% Base abstract class in the Entity objects hierarchy.
% Declares public properties: ID, Description, Comments and protected method Init()
% The class inherits matlab.mixin.Copyable, so instances of classes inherited from
% the BaseEntity can be shallow copied with the syntax: copy(baseEntityImpl)
%
% NOTES:
%
% RELEASE VERSION: 0.6
%
% AUTHOR: Anton Shpak (a.shpak@victorchang.edu.au)
%
% DATE: February 2020
    properties
        ID;
        Description;
        Comments;
    end
    
    methods
        function obj = BaseEntity(id, description, comments)
            if (nargin == 0) % NEED THE EMPTY CONSTRUCTOR FOR ARRAY SUPPORT
                obj.ID = double.empty;
                obj.Description = "";
                obj.Comments = "";
            elseif (nargin == 3)
                obj.ID = id;
                obj.Description = description;
                obj.Comments = comments;
            end
        end
    end
    
    methods (Abstract, Access = protected)
        Init(self, data);
    end
end

