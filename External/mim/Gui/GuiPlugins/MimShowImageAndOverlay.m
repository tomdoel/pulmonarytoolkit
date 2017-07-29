classdef MimShowImageAndOverlay < MimGuiPlugin
    % MimShowImageAndOverlay. Gui Plugin for using a preset bone window/level
    %
    %     You should not use this class within your own code. It is intended to
    %     be used by the gui of the TD MIM Toolkit.
    %
    %     MimShowImageAndOverlay is a Gui Plugin for the MIM Toolkit.
    %
    %
    %     Licence
    %     -------
    %     Part of the TD MIM Toolkit. https://github.com/tomdoel
    %     Author: Tom Doel, Copyright Tom Doel 2014.  www.tomdoel.com
    %     Distributed under the MIT licence. Please see website for details.
    %    
    
    properties
        ButtonText = 'Image & Overlay'
        SelectedText = 'Image & Overlay'
        ToolTip = 'Shows the image and the segmentation'
        Category = 'Segmentation display'
        Visibility = 'Dataset'
        Mode = 'Segment'

        HidePluginInDisplay = false
        PTKVersion = '1'
        ButtonWidth = 6
        ButtonHeight = 1
        Icon = 'show_image.png'
        Location = 23
    end
    
    methods (Static)
        function RunGuiPlugin(gui_app)
            gui_app.ImagePanel.ShowImage = true;
            gui_app.ImagePanel.ShowOverlay = true;
        end
        
        function enabled = IsEnabled(gui_app)
            enabled = gui_app.IsDatasetLoaded && gui_app.ImagePanel.OverlayImage.ImageExists && ~strcmp(gui_app.ImagePanel.Mode, MimModes.View3DMode);
        end
        
        function is_selected = IsSelected(gui_app)
            is_selected = gui_app.ImagePanel.ShowImage && gui_app.ImagePanel.ShowOverlay;
        end
    end
end