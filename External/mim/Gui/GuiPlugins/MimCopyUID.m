classdef MimCopyUID < MimGuiPlugin
    % MimCopyUID. Copy the UID of the current dataset to the clipboard
    %
    %     You should not use this class within your own code. It is intended to
    %     be used by the gui of the Pulmonary Toolkit.
    %
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. https://github.com/tomdoel/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %    

    properties
        ButtonText = 'Copy UID'
        SelectedText = 'Copy UID'
        ToolTip = 'Copy the UID of the current dataset to the clipboard'
        Category = 'Developer tools'
        Visibility = 'Dataset'
        Mode = 'Segment'

        HidePluginInDisplay = false
        PTKVersion = '1'
        ButtonWidth = 4
        ButtonHeight = 1
        
        Location = 103       
    end
    
    methods (Static)
        function RunGuiPlugin(gui_app)
            image_info = gui_app.GetImageInfo;
            uid = image_info.ImageUid;
            disp(['Current dataset UID is: ' uid]);
            clipboard('copy', uid);
        end
        
        function enabled = IsEnabled(gui_app)
            enabled = gui_app.DeveloperMode && gui_app.IsDatasetLoaded;
        end        
    end
end