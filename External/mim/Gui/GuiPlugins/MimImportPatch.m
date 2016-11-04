classdef MimImportPatch < MimGuiPlugin
    % MimImportPatch. Gui Plugin for importing patch files.
    %
    %     You should not use this class within your own code. It is intended to
    %     be used by the gui of the Pulmonary Toolkit.
    %
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. https://github.com/tomdoel/pulmonarytoolkit
    %     Author: Tom Doel, 2014.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %    

    properties
        ButtonText = 'Import Patch'
        SelectedText = 'Import Patch'
        ToolTip = 'Prompts the user to select a patch to import.'
        Category = 'Dataset'
        Visibility = 'Always'
        Mode = 'Toolbar'
        Icon = 'add_patch.png'
        Location = 4

        HidePluginInDisplay = false
        PTKVersion = '1'
        ButtonWidth = 4
        ButtonHeight = 1
    end
    
    methods (Static)
        function RunGuiPlugin(ptk_gui_app)
            ptk_gui_app.ImportPatch();
        end
        
        function enabled = IsEnabled(ptk_gui_app)
            enabled = true;
        end
        
        function is_selected = IsSelected(ptk_gui_app)
            is_selected = false;
        end        
        
    end
end