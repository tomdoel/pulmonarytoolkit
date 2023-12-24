classdef MimImportNewManualSegmentation < MimGuiPlugin
    % MimImportNewManualSegmentation. Gui Plugin 
    %
    %     You should not use this class within your own code. It is intended to
    %     be used by the gui of the TD MIM Toolkit.
    %
    %     MimImportNewManualSegmentation is a Gui Plugin for the MIM Toolkit.
    %
    %
    % .. Licence
    %    -------
    %    Part of the TD MIM Toolkit. https://github.com/tomdoel
    %    Author: Tom Doel, Copyright Tom Doel 2014.  www.tomdoel.com
    %    Distributed under the MIT licence. Please see website for details.
    %    

    properties
        ButtonText = 'Import new segmentation'
        SelectedText = 'Import new segmentation'
        ToolTip = 'Imports a new segmentation from an external file'
        Category = 'Segment region'
        Visibility = 'Dataset'
        Mode = 'Segment'
        
        Icon = 'add_patch.png'
        Location = 26

        HidePluginInDisplay = false
        PTKVersion = '1'
        ButtonWidth = 6
        ButtonHeight = 2
    end
    
    methods (Static)
        function RunGuiPlugin(gui_app)
            gui_app.ImportManualSegmentation();
        end
        
        function enabled = IsEnabled(gui_app)
            enabled = gui_app.IsDatasetLoaded;
        end
        
    end
end