classdef MivGui < PTKGuiCore
    % MivGui Main class for the MIV 3D Medical Image Viewer for Matlab
    %
    %     To run MIV, type
    %
    %         miv
    %
    %     at the Matlab command prompt
    % 
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. https://github.com/tomdoel/pulmonarytoolkit
    %     Author: Tom Doel, 2015.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %
    
    methods
        function obj = MivGui(splash_screen)
            obj = obj@PTKGuiCore(MivAppDef, splash_screen);
        end
    end
end
