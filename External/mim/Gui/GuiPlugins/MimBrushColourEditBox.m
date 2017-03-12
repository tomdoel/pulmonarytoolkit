classdef MimBrushColourEditBox < MimGuiPluginEditBox
    % MimBrushColourEditBox. Gui Plugin for changing the size of the edit brush
    %
    %     You should not use this class within your own code. It is intended to
    %     be used by the gui of the Pulmonary Toolkit.
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. https://github.com/tomdoel/pulmonarytoolkit
    %     Author: Tom Doel, 2014.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %    
    
    properties
        ButtonText = 'Custom'
        SelectedText = 'Custom'
        
        ToolTip = 'Change the colour of the editing paint brush'
        Category = 'Segmentation label'
        Visibility = 'Dataset'
        Mode = 'Edit'

        HidePluginInDisplay = false
        PTKVersion = '2'
        ButtonWidth = 6
        ButtonHeight = 1
        Location = 40

        MinValue = 0
        MaxValue = 255
        DefaultValue = 1
        
        EditBoxPosition = 90
        EditBoxWidth = 25

        StackVertically = false
    end
    
    methods (Static)
        function RunGuiPlugin(gui_app)
        end
        
        function enabled = IsEnabled(gui_app)
            enabled = gui_app.IsDatasetLoaded && gui_app.ImagePanel.OverlayImage.ImageExists && ...
                isequal(gui_app.ImagePanel.SelectedControl, 'Paint');
        end
        
        function is_selected = IsSelected(gui_app)
            is_selected = true;
        end
        
        function [value_instance_handle, value_property_name, limits_instance_handle, limits_property_name] = GetHandleAndProperty(gui_app)
            value_instance_handle = gui_app.ImagePanel;
            value_property_name = 'PaintBrushColour';
            limits_instance_handle = [];
            limits_property_name = [];
        end
        
    end
end