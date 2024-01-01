classdef MimImportRecursive < MimGuiPlugin
    % MimImportRecursive. Gui Plugin for importing and loading image files.
    %
    %     You should not use this class within your own code. It is intended to
    %     be used by the gui of the TD MIM Toolkit.
    %
    %     MimImportRecursive is a Gui Plugin for the MIM Toolkit.
    %     The gui will create a button for the user to run this plugin.
    %     Running this plugin will bring up a dialog box for selecting a folder to
    %     load. The Toolkit will recursively examine subfolders to find and
    %     import datasets.
    %
    %
    % .. Licence
    %    -------
    %    Part of the TD MIM Toolkit. https://github.com/tomdoel
    %    Author: Tom Doel, Copyright Tom Doel 2014.  www.tomdoel.com
    %    Distributed under the MIT licence. Please see website for details.
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
        ButtonWidth = 6
        ButtonHeight = 1
    end
    
    methods (Static)
        function RunGuiPlugin(gui_app)
            uids = gui_app.ImportMultipleFiles();
        end
        
        function enabled = IsEnabled(gui_app)
            enabled = true;
        end
        
        function is_selected = IsSelected(gui_app)
            is_selected = false;
        end        
        
    end
end