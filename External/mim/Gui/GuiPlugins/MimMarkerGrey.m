classdef MimMarkerGrey < MimGuiPlugin
    % MimMarkerGrey. Gui Plugin for switching transparency of zero
    %
    %     You should not use this class within your own code. It is intended to
    %     be used by the gui of the TD MIM Toolkit.
    %
    %     MimMarkerGrey is a Gui Plugin for the MIM Toolkit.
    %
    %
    % .. Licence
    %    -------
    %    Part of the TD MIM Toolkit. https://github.com/tomdoel
    %    Author: Tom Doel, Copyright Tom Doel 2014.  www.tomdoel.com
    %    Distributed under the MIT licence. Please see website for details.
    %    
    
    properties
        ButtonText = 'Grey'
        SelectedText = 'Grey'
        ToolTip = 'Place grey markers'
        Category = 'Marker colour'
        Visibility = 'Dataset'
        Mode = 'Markers'

        HidePluginInDisplay = false
        PTKVersion = '1'
        ButtonWidth = 5
        ButtonHeight = 1
        Icon = 'single_marker.png'
        IconColour = GemMarkerPoint.DefaultColours{7}
        Location = 7
    end
    
    methods (Static)
        function RunGuiPlugin(gui_app)
            gui_app.ImagePanel.NewMarkerColour = 7;
        end
        
        function enabled = IsEnabled(gui_app)
            enabled = gui_app.IsDatasetLoaded && isequal(gui_app.GetCurrentModeName, MimModes.MarkerMode);
        end
        
        function is_selected = IsSelected(gui_app)
            is_selected = gui_app.ImagePanel.NewMarkerColour == 7;
        end
    end
end