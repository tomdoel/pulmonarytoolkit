classdef PTKSegmentSegments < MimGuiPlugin
    % Gui Plugin for activating segment segmentation
    %
    % You should not use this class directly within your own code.
    % It is intended to be used by the GUI of the Pulmonary Toolkit.
    %
    %
    % .. Licence
    %    -------
    %    Part of the TD Pulmonary Toolkit. https://github.com/tomdoel/pulmonarytoolkit
    %    Author: Tom Doel, 2012.  www.tomdoel.com
    %    Distributed under the GNU GPL v3 licence. Please see website for details.
    %    
    
    properties
        ButtonText = 'Segments'
        SelectedText = 'Segments'
        ToolTip = 'Segment the segments'
        Category = 'Segment region'
        Visibility = 'Dataset'
        Mode = 'Segment'

        HidePluginInDisplay = false
        PTKVersion = '1'
        ButtonWidth = 6
        ButtonHeight = 1
        Icon = 'icon_segments.png'
        Location = 4
    end
    
    methods (Static)
        function RunGuiPlugin(gui_app)
            gui_app.RunPluginCallback('PTKPulmonarySegments');
        end

        function enabled = IsEnabled(gui_app)
            enabled = gui_app.DeveloperMode && gui_app.IsDatasetLoaded && (gui_app.IsCT);
        end
        
        function is_selected = IsSelected(gui_app)
            is_selected = gui_app.IsDatasetLoaded && strcmp(gui_app.GetCurrentPluginName, 'PTKSegments');
        end

    end
end
