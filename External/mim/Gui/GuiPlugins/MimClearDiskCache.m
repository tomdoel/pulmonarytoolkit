classdef MimClearDiskCache < MimGuiPlugin
    % MimClearDiskCache. Gui Plugin for deleting all cached results files for the current dataset
    %
    %     You should not use this class within your own code. It is intended to
    %     be used by the gui of the TD MIM Toolkit.
    %
    %     MimClearDiskCache is a Gui Plugin for the MIM Toolkit. 
    %     The gui will create a button for the user to run this plugin.
    %     Running this plugin will delete all results files from the current 
    %     dataset results cache folder. Certain internal cache files will not be
    %     removed.
    %
    %
    %     Licence
    %     -------
    %     Part of the TD MIM Toolkit. https://github.com/tomdoel
    %     Author: Tom Doel, Copyright Tom Doel 2014.  www.tomdoel.com
    %     Distributed under the MIT licence. Please see website for details.
    %    
    
    properties
        ButtonText = 'Delete Cache'
        SelectedText = 'Delete Cache'
        ToolTip = 'Clear all cached results for this dataset'
        Category = 'Developer tools'
        Visibility = 'Dataset'
        Mode = 'Segment'

        HidePluginInDisplay = false
        PTKVersion = '1'
        ButtonWidth = 6
        ButtonHeight = 1
        Location = 105
    end
    
    methods (Static)
        function RunGuiPlugin(gui_app)
            % Delete files from the disk cache and update the plugin previews
            gui_app.ClearCacheForThisDataset;
        end
        
        function enabled = IsEnabled(gui_app)
            enabled = gui_app.DeveloperMode && gui_app.IsDatasetLoaded;
        end        
    end
    
end

