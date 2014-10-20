classdef PTKShowCacheFolder < PTKGuiPlugin
    % PTKShowCacheFolder. Gui Plugin for opening an explorer/finder window in the
    % cache folder of the currently visualised dataset
    %
    %     You should not use this class within your own code. It is intended to
    %     be used by the gui of the Pulmonary Toolkit.
    %
    %     PTKShowCacheFolder is a Gui Plugin for the TD Pulmonary Toolkit.
    %     The gui will create a button for the user to run this plugin.
    %     Running this plugin will reveal the disk cache folder (where all the
    %     results are stored) for the current dataset, by opening a
    %     explorer/finder window in this folder.
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %    

    properties
        ButtonText = 'Open Cache'
        SelectedText = 'Open Cache'
        ToolTip = 'Opens a folder containing the cache files for the current dataset'
        Category = 'File'
        Visibility = 'Developer'
        Mode = 'File'

        HidePluginInDisplay = false
        PTKVersion = '1'
        ButtonWidth = 4
        ButtonHeight = 1
    end
    
    methods (Static)
        function RunGuiPlugin(ptk_gui_app)
            dataset_cache_path = ptk_gui_app.GetDatasetCachePath;
            PTKDiskUtilities.OpenDirectoryWindow(dataset_cache_path);
        end
    end
end