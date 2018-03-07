classdef PTKSegmentLobarBronchi < MimGuiPlugin
    % PTKSegmentLobarBronchi. Gui Plugin for activating airway segmentation
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
        ButtonText = 'Lobar bronchi'
        SelectedText = 'Lobar bronchi'
        ToolTip = 'Segment the airways and labels by lobe'
        Category = 'Segment region'
        Visibility = 'Dataset'
        Mode = 'Segment'

        HidePluginInDisplay = false
        PTKVersion = '1'
        ButtonWidth = 6
        ButtonHeight = 1
        Icon = 'icon_lobarbronchi.png'
        Location = 1
    end
    
    methods (Static)
        function RunGuiPlugin(gui_app)
            gui_app.RunPluginCallback('PTKAirwaysLabelledByLobe');
        end

        function enabled = IsEnabled(gui_app)
            enabled = gui_app.IsDatasetLoaded && gui_app.IsCT;
        end
        
        function is_selected = IsSelected(gui_app)
            is_selected = gui_app.IsDatasetLoaded && strcmp(gui_app.GetCurrentPluginName, 'PTKAirwaysLabelledByLobe');
        end

    end
end