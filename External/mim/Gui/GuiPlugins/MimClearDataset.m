classdef MimClearDataset < MimGuiPlugin
    % MimClearDataset. Gui Plugin for displaying an "about box" dialog
    %
    %     You should not use this class within your own code. It is intended to
    %     be used by the gui of the TD MIM Toolkit.
    %
    %     MimClearDataset is a Gui Plugin for the MIM Toolkit. The gui will
    %     create a button to run this plugin. Running this plugin will cause a
    %     splash screen dialog to be displayed.
    %
    %
    %     Licence
    %     -------
    %     Part of the TD MIM Toolkit. https://github.com/tomdoel
    %     Author: Tom Doel, Copyright Tom Doel 2014.  www.tomdoel.com
    %     Distributed under the MIT licence. Please see website for details.
    %    
    
    properties
        ButtonText = 'No Dataset'
        SelectedText = 'No Dataset'
        ToolTip = ''
        Category = 'Developer tools'
        Visibility = 'Developer'
        Mode = 'Segment'

        HidePluginInDisplay = false
        PTKVersion = '1'
        ButtonWidth = 4
        ButtonHeight = 1
        
        Location = 101
    end
    
    methods (Static)
        function RunGuiPlugin(gui_app)
            gui_app.ClearDataset;
        end
        
        function enabled = IsEnabled(gui_app)
            enabled = gui_app.DeveloperMode && gui_app.IsDatasetLoaded;
        end        
        
    end
end