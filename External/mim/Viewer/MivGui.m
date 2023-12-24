classdef MivGui < MimGuiBase
    % MivGui Main class for the MIV 3D Medical Image Viewer for Matlab
    %
    %     To run MIV, type
    %
    %         miv
    %
    %     at the Matlab command prompt
    % 
    %
    % .. Licence
    %    -------
    %    Part of the TD MIM Toolkit. https://github.com/tomdoel
    %    Author: Tom Doel, Copyright Tom Doel 2014.  www.tomdoel.com
    %    Distributed under the MIT licence. Please see website for details.
    %
    
    methods
        function obj = MivGui(splash_screen)
            obj = obj@MimGuiBase(MivAppDef, splash_screen);
        end
    end
end
