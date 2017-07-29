classdef MimShowMarkers < MimGuiPlugin
    % MimShowMarkers. Gui Plugin for entering marker edit mode
    %
    %     You should not use this class within your own code. It is intended to
    %     be used by the gui of the TD MIM Toolkit.
    %
    %     MimEnterMarkerMode is a Gui Plugin for showing or hiding markers
    %
    %
    %     Licence
    %     -------
    %     Part of the TD MIM Toolkit. https://github.com/tomdoel
    %     Author: Tom Doel, Copyright Tom Doel 2014.  www.tomdoel.com
    %     Distributed under the MIT licence. Please see website for details.
    %    
    
    properties
        ButtonText = 'Show Markers'
        SelectedText = 'Hide Markers'
        ToolTip = 'Enters marker edit mode'
        Category = 'Marker display'
        Visibility = 'Dataset'
        Mode = 'Markers'

        HidePluginInDisplay = false
        PTKVersion = '2'
        ButtonWidth = 6
        ButtonHeight = 1
        Location = 1
        Icon = 'markers.png'
    end
    
    methods (Static)
        function RunGuiPlugin(gui_app)
            gui_app.ImagePanel.ShowMarkers = ~gui_app.ImagePanel.ShowMarkers;
        end

        function enabled = IsEnabled(gui_app)
            enabled = gui_app.IsDatasetLoaded;
        end
        
        function is_selected = IsSelected(gui_app)
            is_selected = gui_app.ImagePanel.ShowMarkers;
        end
    end
end