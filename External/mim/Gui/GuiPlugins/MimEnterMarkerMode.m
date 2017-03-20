classdef MimEnterMarkerMode < MimGuiPlugin
    % MimEnterMarkerMode. Gui Plugin for entering marker edit mode
    %
    %     You should not use this class within your own code. It is intended to
    %     be used by the gui of the TD MIM Toolkit.
    %
    %     MimEnterMarkerMode is a Gui Plugin for entering or leaving marker mode.
    %
    %
    %     Licence
    %     -------
    %     Part of the TD MIM Toolkit. https://github.com/tomdoel
    %     Author: Tom Doel, Copyright Tom Doel 2014.  www.tomdoel.com
    %     Distributed under the MIT licence. Please see website for details.
    %    
    
    properties
        ButtonText = 'Edit Markers'
        SelectedText = 'Hide Markers'
        ToolTip = 'Enters marker edit mode'
        Category = 'Show / hide'
        Visibility = 'Dataset'
        Mode = 'Toolbar'

        HidePluginInDisplay = false
        PTKVersion = '2'
        ButtonWidth = 6
        ButtonHeight = 1
        Location = 11
        Icon = 'markers.png'
    end
    
    methods (Static)
        function RunGuiPlugin(gui_app)
            if gui_app.ImagePanel.IsInMarkerMode
                gui_app.ImagePanel.SetControl('W/L');
            else
                gui_app.ImagePanel.SetControl('Mark');
            end
            
        end

        function enabled = IsEnabled(gui_app)
            enabled = gui_app.IsDatasetLoaded;
        end
        
        function is_selected = IsSelected(gui_app)
            is_selected = gui_app.ImagePanel.IsInMarkerMode;
        end
    end
end