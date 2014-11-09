classdef PTKWindowSlider < PTKGuiPluginSlider
    % PTKWindowSlider. Gui Plugin for changing overlay opacity
    %
    %     You should not use this class within your own code. It is intended to
    %     be used by the gui of the Pulmonary Toolkit.
    %
    %     PTKWindowSlider is a Gui Plugin for changing the value of the
    %     window used to display the greyscale image
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2014.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %    
    
    properties
        ButtonText = 'Window'
        SelectedText = 'Window'
        ToolTip = 'Change the window'
        Category = 'Window / Level'
        Visibility = 'Dataset'
        Mode = 'Toolbar'

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
        
        EditBoxPosition = 90
        EditBoxWidth = 50
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
        
        function [instance_handle, value_property_name, limits_property_name] = GetHandleAndProperty(ptk_gui_app)
            instance_handle = ptk_gui_app.ImagePanel;
            value_property_name = 'Window';
            limits_property_name = 'WindowLimits';
        end
        
    end
end