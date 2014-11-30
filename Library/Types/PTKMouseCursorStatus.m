classdef PTKMouseCursorStatus < handle
    % PTKMouseCursorStatus. Data representing the voxel under the mouse cursor
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2014.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
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

