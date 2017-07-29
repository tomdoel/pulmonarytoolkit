classdef MimOpacitySlider < MimGuiPluginSlider
    % MimOpacitySlider. Gui Plugin for changing overlay opacity
    %
    %     You should not use this class within your own code. It is intended to
    %     be used by the gui of the TD MIM Toolkit.
    %
    %     MimOpacitySlider is a Gui Plugin for changing the opacity of the
    %     segmentation overlay
    %
    %
    %     Licence
    %     -------
    %     Part of the TD MIM Toolkit. https://github.com/tomdoel
    %     Author: Tom Doel, Copyright Tom Doel 2014.  www.tomdoel.com
    %     Distributed under the MIT licence. Please see website for details.
    %    
    
    properties
        ButtonText = 'Opacity'
        SelectedText = 'Opacity'
        ToolTip = 'Change the transparency of the segmentation overlay'
        Category = 'Segmentation display'
        Visibility = 'Dataset'
        Mode = 'Segment'

        HidePluginInDisplay = false
        PTKVersion = '2'
        ButtonWidth = 6
        ButtonHeight = 1
        Location = 25

        MinValue = 0
        MaxValue = 100
        SmallStep = 0.01
        LargeStep = 0.1
        DefaultValue = 50
        
        EditBoxPosition = 75
        EditBoxWidth = 30
        StackVertically = false
    end
    
    methods (Static)
        function RunGuiPlugin(gui_app)
        end
        
        function enabled = IsEnabled(gui_app)
            enabled = gui_app.IsDatasetLoaded && gui_app.ImagePanel.OverlayImage.ImageExists && ~strcmp(gui_app.ImagePanel.Mode, MimModes.View3DMode) && gui_app.ImagePanel.ShowOverlay;
        end
        
        function is_selected = IsSelected(gui_app)
            is_selected = true;
        end
        
        function [value_instance_handle, value_property_name, limits_istance_handle, limits_property_name] = GetHandleAndProperty(gui_app)
            value_instance_handle = gui_app.ImagePanel.GetOverlayImageDisplayParameters;
            value_property_name = 'Opacity';
            limits_istance_handle = [];
            limits_property_name = [];
        end
        
    end
end