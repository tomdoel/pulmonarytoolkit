classdef PTKSegmentSegments < PTKGuiPlugin
    % PTKSegmentSegments. Gui Plugin for activating segment segmentation
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
        function RunGuiPlugin(ptk_gui_app)
            ptk_gui_app.RunPluginCallback('PTKPulmonarySegments');
        end

        function enabled = IsEnabled(ptk_gui_app)
            enabled = ptk_gui_app.IsDatasetLoaded && (ptk_gui_app.IsCT || ptk_gui_app.IsMR);
        end
        
        function is_selected = IsSelected(ptk_gui_app)
            is_selected = ptk_gui_app.IsDatasetLoaded && strcmp(ptk_gui_app.GetCurrentPluginName, 'PTKSegments');
        end

    end
end