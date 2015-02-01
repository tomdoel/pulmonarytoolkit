classdef PTKOpacitySlider < PTKGuiPluginSlider
    % PTKOpacitySlider. Gui Plugin for changing overlay opacity
    %
    %     You should not use this class within your own code. It is intended to
    %     be used by the gui of the Pulmonary Toolkit.
    %
    %     PTKOpacitySlider is a Gui Plugin for changing the opacity of the
    %     segmentation overlay
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2014.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %    
    
    properties
        ButtonText = 'Overlay Transparency'
        SelectedText = 'Overlay Transparency'
        ToolTip = 'Change the transparency of the segmentation overlay'
        Category = 'Segmentation overlay'
        Visibility = 'Dataset'
        Mode = 'View'

        HidePluginInDisplay = false
        PTKVersion = '2'
        ButtonWidth = 6
        ButtonHeight = 1
        Location = 9

        MinValue = 0
        MaxValue = 100
        SmallStep = 0.01
        LargeStep = 0.1
        DefaultValue = 50
        
        EditBoxPosition = 130
        EditBoxWidth = 40
    end
    
    methods (Static)
        function RunGuiPlugin(ptk_gui_app)
        end
        
        function enabled = IsEnabled(ptk_gui_app)
            enabled = ptk_gui_app.IsDatasetLoaded && ptk_gui_app.ImagePanel.OverlayImage.ImageExists;
        end
        
        function is_selected = IsSelected(ptk_gui_app)
            is_selected = true;
        end
        
        function [instance_handle, value_property_name, limits_property_name] = GetHandleAndProperty(ptk_gui_app)
            instance_handle = ptk_gui_app.ImagePanel;
            value_property_name = 'OverlayOpacity';
            limits_property_name = [];
        end
        
    end
end