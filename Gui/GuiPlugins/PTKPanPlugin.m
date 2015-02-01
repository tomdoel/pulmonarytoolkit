classdef PTKPanPlugin < PTKGuiPlugin
    % PTKPanPlugin. Gui Plugin for using a preset bone window/level
    %
    %     You should not use this class within your own code. It is intended to
    %     be used by the gui of the Pulmonary Toolkit.
    %
    %     PTKPanPlugin is a Gui Plugin for the TD Pulmonary Toolkit.
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2014.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %    
    
    properties
        ButtonText = 'Pan'
        SelectedText = 'Pan'
        ToolTip = 'Enables Matlab''s pan tool'
        Category = 'Tools'
        Visibility = 'Dataset'
        Mode = 'Toolbar'

        HidePluginInDisplay = false
        PTKVersion = '1'
        ButtonWidth = 6
        ButtonHeight = 1
        Icon = 'pan.png'
        Location = 14
    end
    
    methods (Static)
        function RunGuiPlugin(ptk_gui_app)
            ptk_gui_app.ImagePanel.SetControl('Pan');
        end
        
        function enabled = IsEnabled(ptk_gui_app)
            enabled = ptk_gui_app.IsDatasetLoaded;
        end
        
        function is_selected = IsSelected(ptk_gui_app)
            is_selected = strcmp(ptk_gui_app.ImagePanel.SelectedControl, 'Pan');
        end
        
    end
end