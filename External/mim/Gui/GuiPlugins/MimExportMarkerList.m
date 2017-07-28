classdef MimExportMarkerList < MimGuiPlugin
    % MimExportMarkerList. Gui Plugin 
    %
    %     You should not use this class within your own code. It is intended to
    %     be used by the gui of the TD MIM Toolkit.
    %
    %     MimExportMarkerList is a Gui Plugin for the MIM Toolkit.
    %
    %
    %     Licence
    %     -------
    %     Part of the TD MIM Toolkit. https://github.com/tomdoel
    %     Author: Tom Doel, Copyright Tom Doel 2014.  www.tomdoel.com
    %     Distributed under the MIT licence. Please see website for details.
    %    

    properties
        ButtonText = 'Export Markers'
        SelectedText = 'Export Markers'
        ToolTip = 'Exports the current marker set to an external file'
        Category = 'Marker display'
        Visibility = 'Dataset'
        Mode = 'Markers'

        Icon = 'save_markers.png'

        HidePluginInDisplay = false
        PTKVersion = '1'
        ButtonWidth = 6
        ButtonHeight = 2
        Location = 3
    end
    
    methods (Static)
        function RunGuiPlugin(gui_app)
            gui_app.ExportMarkers();
        end
        
        function enabled = IsEnabled(gui_app)
            enabled = gui_app.IsDatasetLoaded && isequal(gui_app.GetCurrentModeName, MimModes.MarkerMode);
        end
        
        function is_selected = IsSelected(gui_app)
            is_selected = false;
        end        
    end
end