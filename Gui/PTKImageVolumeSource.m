classdef PTKImageVolumeSource < CoreBaseClass
    % PTKImageVolumeSource. Part of the gui for the Pulmonary Toolkit.
    %
    %     This class is used internally within the Pulmonary Toolkit to help
    %     build the user interface.
    %
    %     PTKImageVolumeSource .
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. https://github.com/tomdoel/pulmonarytoolkit
    %     Author: Tom Doel, 2014.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %
    
    properties (Access = private)
        ViewerPanel
    end
    
    methods
        
        function obj = PTKImageVolumeSource(viewer_panel)
            obj = obj@CoreBaseClass;
            obj.ViewerPanel = viewer_panel;
        end
        
        function orientation = GetOrientation(obj)
            orientation = obj.ViewerPanel.Orintation;
        end

        function orientation = GetBackgroundImage(obj)
            orientation = obj.ViewerPanel.BackgroundImage;
        end
    end
    
end