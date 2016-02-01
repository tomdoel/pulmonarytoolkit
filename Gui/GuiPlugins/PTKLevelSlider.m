classdef PTKLevelSlider < PTKGuiPluginSlider
    % PTKLevelSlider. Gui Plugin for changing overlay opacity
    %
    %     You should not use this class within your own code. It is intended to
    %     be used by the gui of the Pulmonary Toolkit.
    %
    %     PTKLevelSlider is a Gui Plugin for changing the value of the
    %     window used to display the greyscale image
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. https://github.com/tomdoel/pulmonarytoolkit
    %     Author: Tom Doel, 2014.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %    
    
    properties
        ButtonText = 'Level'
        SelectedText = 'Level'
        ToolTip = 'Change the level'
        Category = 'Window / Level'
        Visibility = 'Dataset'
        Mode = 'Toolbar'

        HidePluginInDisplay = false
        PTKVersion = '2'
        ButtonWidth = 4
        ButtonHeight = 1
        Location = 26

        MinValue = 0
        MaxValue = 100
        SmallStep = 0.01
        LargeStep = 0.1
        DefaultValue = 50
        
        EditBoxPosition = 50
        EditBoxWidth = 40
        
        StackVertically = true
    end
    
    methods (Static)
        function RunGuiPlugin(ptk_gui_app)
        end
        
        function enabled = IsEnabled(ptk_gui_app)
            enabled = ptk_gui_app.IsDatasetLoaded;
        end
        
        function is_selected = IsSelected(ptk_gui_app)
            is_selected = true;
        end
        
        function [value_instance_handle, value_property_name, limits_instance_handle, limits_property_name] = GetHandleAndProperty(ptk_gui_app)
            value_instance_handle = ptk_gui_app.ImagePanel.GetBackgroundImageDisplayParameters;
            value_property_name = 'Level';
            limits_instance_handle = ptk_gui_app.ImagePanel;
            limits_property_name = 'LevelLimits';
        end
        
    end
end