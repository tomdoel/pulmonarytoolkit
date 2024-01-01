classdef MimShowOutputFolder < MimGuiPlugin
    % MimShowOutputFolder. Gui Plugin for opening an explorer/finder window in the
    % cache folder of the currently visualised dataset
    %
    %     You should not use this class within your own code. It is intended to
    %     be used by the gui of the TD MIM Toolkit.
    %
    %     MimShowOutputFolder is a Gui Plugin for the MIM Toolkit.
    %
    %
    % .. Licence
    %    -------
    %    Part of the TD MIM Toolkit. https://github.com/tomdoel
    %    Author: Tom Doel, Copyright Tom Doel 2014.  www.tomdoel.com
    %    Distributed under the MIT licence. Please see website for details.
    %    

    properties
        ButtonText = 'Show output files'
        SelectedText = 'Show output files'
        ToolTip = 'Opens a folder containing the output files for the current dataset'
        Category = 'Results'
        Visibility = 'Dataset'
        Mode = 'Analysis'

        HidePluginInDisplay = false
        PTKVersion = '1'
        ButtonWidth = 6
        ButtonHeight = 2
        Location = 41
        Icon = 'output_files.png'
    end
    
    methods (Static)
        function RunGuiPlugin(gui_app)
            dataset_cache_path = gui_app.GetOutputPath;
            CoreDiskUtilities.OpenDirectoryWindow(dataset_cache_path);
        end
    end
end