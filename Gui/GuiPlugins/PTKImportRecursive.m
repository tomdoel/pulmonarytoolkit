classdef PTKImportRecursive < PTKGuiPlugin
    % PTKImportRecursive. Gui Plugin for importing and loading image files.
    %
    %     You should not use this class within your own code. It is intended to
    %     be used by the gui of the Pulmonary Toolkit.
    %
    %     PTKImportRecursive is a Gui Plugin for the TD Pulmonary Toolkit.
    %     The gui will create a button for the user to run this plugin.
    %     Running this plugin will bring up a dialog box for selecting a folder to
    %     load. The Toolkit will recursively examine subfolders to find and
    %     import datasets.
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %    

    properties
        ButtonText = 'Import Data'
        SelectedText = 'Import Data'
        ToolTip = 'Prompts the user to select a directory to import data from. All data in this directory and its subdirectories will be imported.'
        Category = 'Dataset'
        Visibility = 'Always'
        Mode = 'Toolbar'
        Icon = 'add.png'
        Location = 2

        HidePluginInDisplay = false
        PTKVersion = '1'
        ButtonWidth = 4
        ButtonHeight = 1
    end
    
    methods (Static)
        function RunGuiPlugin(ptk_gui_app)
            ptk_gui_app.ImportMultipleFiles();
        end
        
        function enabled = IsEnabled(ptk_gui_app)
            enabled = true;
        end
        
        function is_selected = IsSelected(ptk_gui_app)
            is_selected = false;
        end        
        
    end
end