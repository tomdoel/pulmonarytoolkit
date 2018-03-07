classdef MimMouseCursorStatus < handle
    % MimMouseCursorStatus. Data representing the voxel under the mouse cursor
    %
    %
    %     Licence
    %     -------
    %     Part of the TD MIM Toolkit. https://github.com/tomdoel
    %     Author: Tom Doel, Copyright Tom Doel 2014.  www.tomdoel.com
    %     Distributed under the MIT licence. Please see website for details.
    %    
    
    properties
        GlobalCoordX
        GlobalCoordY
        GlobalCoordZ
        
        ImageExists
        
        ImageValue
        RescaledValue
        RescaleUnits
        OverlayValue
    end    
end

