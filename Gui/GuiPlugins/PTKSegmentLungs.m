classdef PTKSegmentLungs < MimGuiPlugin
    % PTKSegmentLungs. Gui Plugin for activating lung segmentation
    %
    %     You should not use this class within your own code. It is intended to
    %     be used by the gui of the Pulmonary Toolkit.
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. https://github.com/tomdoel/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %    
    
    properties
        ButtonText = 'Lungs'
        SelectedText = 'Lungs'
        ToolTip = 'Segment the lungs'
        Category = 'Segment region'
        Visibility = 'Dataset'
        Mode = 'Segment'

        HidePluginInDisplay = false
        PTKVersion = '1'
        ButtonWidth = 6
        ButtonHeight = 1
        Icon = 'icon_lungs.png'
        Location = 2
    end
    
    methods (Static)
        function RunGuiPlugin(gui_app)
            gui_app.RunPluginCallback('PTKLeftAndRightLungs');
        end

        function enabled = IsEnabled(gui_app)
            enabled = gui_app.IsDatasetLoaded && (gui_app.IsCT || gui_app.IsMR);
        end
        
        function is_selected = IsSelected(gui_app)
            is_selected = gui_app.IsDatasetLoaded && strcmp(gui_app.GetCurrentPluginName, 'PTKLeftAndRightLungs');
        end

    end
end