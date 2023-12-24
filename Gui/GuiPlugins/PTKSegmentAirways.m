classdef PTKSegmentAirways < MimGuiPlugin
    % Gui Plugin for activating airway segmentation
    %
    % You should not use this class directly within your own code.
    % It is intended to be used by the gui of the Pulmonary Toolkit.
    %
    %
    % .. Licence
    %    -------
    %    Part of the TD Pulmonary Toolkit. https://github.com/tomdoel/pulmonarytoolkit
    %    Author: Tom Doel, 2012.  www.tomdoel.com
    %    Distributed under the GNU GPL v3 licence. Please see website for details.
    %    
    
    properties
        ButtonText = 'Airways'
        SelectedText = 'Airways'
        ToolTip = 'Segment the airways'
        Category = 'Segment region'
        Visibility = 'Dataset'
        Mode = 'Segment'

        HidePluginInDisplay = false
        PTKVersion = '1'
        ButtonWidth = 6
        ButtonHeight = 1
        Icon = 'icon_airways.png'
        Location = 1
    end
    
    methods (Static)
        function RunGuiPlugin(gui_app)
            gui_app.RunPluginCallback('PTKAirways');
        end

        function enabled = IsEnabled(gui_app)
            enabled = gui_app.IsDatasetLoaded && (gui_app.IsCT || gui_app.IsMR);
        end
        
        function is_selected = IsSelected(gui_app)
            is_selected = gui_app.IsDatasetLoaded && strcmp(gui_app.GetCurrentPluginName, 'PTKAirways');
        end

    end
end
