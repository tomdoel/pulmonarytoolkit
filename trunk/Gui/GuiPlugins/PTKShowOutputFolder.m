classdef PTKShowOutputFolder < PTKGuiPlugin
    % PTKShowOutputFolder. Gui Plugin for opening an explorer/finder window in the
    % cache folder of the currently visualised dataset
    %
    %     You should not use this class within your own code. It is intended to
    %     be used by the gui of the Pulmonary Toolkit.
    %
    %     PTKShowOutputFolder is a Gui Plugin for the TD Pulmonary Toolkit.
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %    

    properties
        ButtonText = 'Open the results folder (output folder) for this dataset'
        ToolTip = 'Opens a folder containing the output files for the current dataset'
        Category = 'File'
        Visibility = 'Dataset'
        Mode = 'Analysis'

        HidePluginInDisplay = false
        PTKVersion = '1'
        ButtonWidth = 14
        ButtonHeight = 2
    end
    
    methods (Static)
        function RunGuiPlugin(ptk_gui_app)
            dataset_cache_path = ptk_gui_app.GetOutputPath;
            PTKDiskUtilities.OpenDirectoryWindow(dataset_cache_path);
        end
    end
end