classdef PTKBackgroundScreenImageFromVolume < PTKScreenImageFromVolume
    % PTKBackgroundScreenImageFromVolume. Part of the gui for the Pulmonary Toolkit.
    %
    %     This class is used internally within the Pulmonary Toolkit to help
    %     build the user interface.
    %
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
        function obj = PTKBackgroundScreenImageFromVolume(parent, image_source, viewer_panel)
            obj = obj@PTKScreenImageFromVolume(parent, image_source);
            obj.ViewerPanel = viewer_panel;
        end
        
        function DrawImage(obj)
            obj.DrawImageSlice(obj.ViewerPanel.BackgroundImage, obj.ViewerPanel.BackgroundImage, 100*obj.ViewerPanel.ShowImage, false, obj.ViewerPanel.Window, obj.ViewerPanel.Level, obj.ViewerPanel.OpaqueColour, obj.ViewerPanel.SliceNumber(obj.ViewerPanel.Orientation), obj.ViewerPanel.Orientation);
        end

        function SetRangeWithPositionAdjustment(obj, x_range, y_range)
            obj.SetRange(x_range, y_range);
        end
    end
end