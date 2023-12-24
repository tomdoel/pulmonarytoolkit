classdef MimMarkerMagenta < MimGuiPlugin
    % MimMarkerMagenta. Gui Plugin for switching transparency of zero
    %
    %     You should not use this class within your own code. It is intended to
    %     be used by the gui of the TD MIM Toolkit.
    %
    %     MimMarkerMagenta is a Gui Plugin for the MIM Toolkit.
    %
    %
    % .. Licence
    %    -------
    %    Part of the TD MIM Toolkit. https://github.com/tomdoel
    %    Author: Tom Doel, Copyright Tom Doel 2014.  www.tomdoel.com
    %    Distributed under the MIT licence. Please see website for details.
    %    
    
    properties
        ButtonText = 'Magenta'
        SelectedText = 'Magenta'
        ToolTip = 'Place magenta markers'
        Category = 'Marker colour'
        Visibility = 'Dataset'
        Mode = 'Markers'

        HidePluginInDisplay = false
        PTKVersion = '1'
        ButtonWidth = 5
        ButtonHeight = 1
        Icon = 'single_marker.png'
        IconColour = GemMarkerPoint.DefaultColours{5}
        Location = 5
    end
    
    methods (Static)
        function RunGuiPlugin(gui_app)
            gui_app.ImagePanel.NewMarkerColour = 5;
        end
        
        function enabled = IsEnabled(gui_app)
            enabled = gui_app.IsDatasetLoaded && isequal(gui_app.GetCurrentModeName, MimModes.MarkerMode);
        end
        
        function is_selected = IsSelected(gui_app)
            is_selected = gui_app.ImagePanel.NewMarkerColour == 5;
        end
    end
end