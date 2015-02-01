classdef PTKScreenImageVolumeSource < PTKBaseClass
    % PTKScreenImageVolumeSource. Part of the gui for the Pulmonary Toolkit.
    %
    %     This class is used internally within the Pulmonary Toolkit to help
    %     build the user interface.
    %
    %     PTKScreenImageVolumeSource .
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2014.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %
    
    properties (Access = private)
        ViewerPanel
    end
    
    methods
        
        function obj = PTKScreenImageVolumeSource(viewer_panel)
            obj = obj@PTKBaseClass;
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