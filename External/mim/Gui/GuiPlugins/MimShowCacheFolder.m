classdef MimShowCacheFolder < MimGuiPlugin
    % MimShowCacheFolder. Gui Plugin for opening an explorer/finder window in the
    % cache folder of the currently visualised dataset
    %
    %     You should not use this class within your own code. It is intended to
    %     be used by the gui of the TD MIM Toolkit.
    %
    %     MimShowCacheFolder is a Gui Plugin for the MIM Toolkit.
    %     The gui will create a button for the user to run this plugin.
    %     Running this plugin will reveal the disk cache folder (where all the
    %     results are stored) for the current dataset, by opening a
    %     explorer/finder window in this folder.
    %
    %
    %     Licence
    %     -------
    %     Part of the TD MIM Toolkit. https://github.com/tomdoel
    %     Author: Tom Doel, Copyright Tom Doel 2014.  www.tomdoel.com
    %     Distributed under the MIT licence. Please see website for details.
    %    

    properties
        ButtonText = 'Open Cache'
        SelectedText = 'Open Cache'
        ToolTip = 'Opens a folder containing the cache files for the current dataset'
        Category = 'Developer tools'
        Visibility = 'Developer'
        Mode = 'Segment'

        HidePluginInDisplay = false
        PTKVersion = '1'
        ButtonWidth = 6
        ButtonHeight = 1
        Location = 107
    end
    
    methods (Static)
        function RunGuiPlugin(gui_app)
            dataset_cache_path = gui_app.GetDatasetCachePath;
            CoreDiskUtilities.OpenDirectoryWindow(dataset_cache_path);
        end
        
        function enabled = IsEnabled(gui_app)
            enabled = gui_app.DeveloperMode && gui_app.IsDatasetLoaded;
        end        
    end
end