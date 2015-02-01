classdef PTKClearDataset < PTKGuiPlugin
    % PTKAboutPtk. Gui Plugin for displaying an "about box" dialog
    %
    %     You should not use this class within your own code. It is intended to
    %     be used by the gui of the Pulmonary Toolkit.
    %
    %     PTKAboutPtk is a Gui Plugin for the TD Pulmonary Toolkit. The gui will
    %     create a button to run this plugin. Running this plugin will cause a
    %     splash screen dialog to be displayed.
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %    
    
    properties
        ButtonText = 'No Dataset'
        SelectedText = 'No Dataset'
        ToolTip = ''
        Category = 'File'
        Visibility = 'Developer'
        Mode = 'View'

        HidePluginInDisplay = false
        PTKVersion = '1'
        ButtonWidth = 4
        ButtonHeight = 1
        
        Location = 18
    end
    
    methods (Static)
        function RunGuiPlugin(ptk_gui_app)
            ptk_gui_app.ClearDataset;
        end
        
        function enabled = IsEnabled(ptk_gui_app)
            enabled = ptk_gui_app.DeveloperMode && ptk_gui_app.IsDatasetLoaded;
        end        
        
    end
end