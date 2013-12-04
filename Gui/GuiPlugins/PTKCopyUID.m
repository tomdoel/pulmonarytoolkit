classdef PTKCopyUID < PTKGuiPlugin
    % PTKCopyUID. Copy the UID of the current dataset to the clipboard
    %
    %     You should not use this class within your own code. It is intended to
    %     be used by the gui of the Pulmonary Toolkit.
    %
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %    

    properties
        ButtonText = 'Copy UID'
        ToolTip = 'Copy the UID of the current dataset to the clipboard'
        Category = 'File'
        Visibility = 'Dataset'

        HidePluginInDisplay = false
        PTKVersion = '1'
        ButtonWidth = 4
        ButtonHeight = 1
    end
    
    methods (Static)
        function RunGuiPlugin(ptk_gui_app)
            image_info = ptk_gui_app.GetImageInfo;
            uid = image_info.ImageUid;
            disp(['Current dataset UID is: ' uid]);
            clipboard('copy', uid);
        end
    end
end