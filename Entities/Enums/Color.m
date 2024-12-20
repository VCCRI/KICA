classdef Color
% CLASS DESCRIPTION: 
% structure (enum) with static/constant colors definitions
% Example of use: Color.Green or Color.LightBlue
%
% NOTES:
%
% RELEASE VERSION: 0.6
%
% AUTHOR: Anton Shpak (a.shpak@victorchang.edu.au)
%
% DATE: February 2020

    properties (Constant)
        Red         = Color.HexToRGB('#A2142F');
        DarkRed     = Color.HexToRGB('#D95319');
        Watermelon	= Color.HexToRGB('#FE7F9C');
        DeepPink    = Color.HexToRGB('#FF1493');
        

        Orange      = Color.HexToRGB('#FFA500');
        Yellow      = Color.HexToRGB('#F6D326');
        DarkYellow  = Color.HexToRGB('#EDB120');
        Ochre       = Color.HexToRGB('#E2A518');
        
        Green        = Color.HexToRGB('#77AC30');
        DarkGreen    = Color.HexToRGB('#013220');
        LightGreen    = Color.HexToRGB('#C0DFC4');
        
        LightBlue	= Color.HexToRGB('#4DBEEE');
        Blue        = Color.HexToRGB('#0080FF');
        DarkBlue    = Color.HexToRGB('#0072BD');
        
        Purple        = Color.HexToRGB('#7E2F8E');
        
        White        = Color.HexToRGB('#FFFFFF');
        Black        = Color.HexToRGB('#000000');
    end
    
    methods (Static, Access = private)
        
        function rgb = HexToRGB(hex)
            rgb = sscanf(hex(2:end),'%2x%2x%2x',[1 3])/255;
        end
        
    end
end